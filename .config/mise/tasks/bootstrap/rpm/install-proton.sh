#!/bin/sh
#MISE description="Install or update a Proton desktop RPM from its release manifest"
#MISE hide=true
#USAGE arg "<package>" help="Installed RPM package name"
#USAGE arg "<manifest-url>" help="Proton Linux version.json URL"
#USAGE flag "--category <category>" default="Stable" help="Proton release category"

set -eu

package_name=${usage_package:?}
manifest_url=${usage_manifest_url:?}
category=${usage_category:-Stable}

[ "$(uname -s)" = "Linux" ] || exit 0
[ "$(uname -m)" = "x86_64" ] || exit 0
command -v rpm >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

if command -v rpm-ostree >/dev/null 2>&1 && rpm-ostree status >/dev/null 2>&1; then
  installer=rpm-ostree
elif command -v dnf >/dev/null 2>&1; then
  installer=dnf
else
  exit 0
fi

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
manifest="$tmpdir/version.json"
release="$tmpdir/release.json"
rpm_file="$tmpdir/proton.rpm"

curl -fsSL -o "$manifest" "$manifest_url"

if ! jq -e --arg category "$category" '
  def semver_key:
    (.Version | split(".") | map(tonumber) | . + [0, 0, 0] | .[0:3]);

  .Releases
  | map(select(.CategoryName == $category))
  | max_by(semver_key)
  | . as $release
  | .File[]
  | select(.Identifier == ".rpm (Fedora/RHEL)")
  | {
      version: $release.Version,
      url: .Url,
      sha512: .Sha512CheckSum
    }
' "$manifest" >"$release"; then
  echo "could not find a $category Proton RPM in $manifest_url" >&2
  exit 1
fi

version=$(jq -er '.version' "$release")
rpm_url=$(jq -er '.url' "$release")
rpm_sha512=$(jq -er '.sha512' "$release")

if installed_version=$(rpm -q --qf '%{VERSION}' "$package_name" 2>/dev/null); then
  if [ "$installed_version" = "$version" ]; then
    echo "$package_name $version is already installed"
    exit 0
  fi
fi

curl -fsSL -o "$rpm_file" "$rpm_url"
printf '%s  %s\n' "$rpm_sha512" "$rpm_file" | sha512sum --check --status

rpm_package_name=$(rpm -qp --qf '%{NAME}' "$rpm_file")
rpm_version=$(rpm -qp --qf '%{VERSION}' "$rpm_file")
rpm_arch=$(rpm -qp --qf '%{ARCH}' "$rpm_file")

if [ "$rpm_version" != "$version" ]; then
  echo "manifest version is $version, but the RPM version is $rpm_version" >&2
  exit 1
fi

if [ "$rpm_package_name" != "$package_name" ]; then
  echo "manifest RPM package is $rpm_package_name, expected $package_name" >&2
  exit 1
fi

if [ "$rpm_arch" != "x86_64" ]; then
  echo "manifest RPM architecture is $rpm_arch, expected x86_64" >&2
  exit 1
fi

case "$installer" in
  rpm-ostree)
    rpm-ostree uninstall --idempotent "$rpm_package_name" >/dev/null 2>&1 || true
    rpm-ostree install --idempotent "$rpm_file"
    ;;
  dnf)
    sudo dnf install -y "$rpm_file"
    ;;
esac
