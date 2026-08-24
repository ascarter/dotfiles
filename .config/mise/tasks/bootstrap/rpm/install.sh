#!/bin/sh
#MISE description="Install an RPM from a URL"
#MISE hide=true
#USAGE arg "<name>" help="RPM package name"
#USAGE arg "<url>" help="RPM package URL"

set -eu

package=${usage_name:?}
rpm_url=${usage_url:?}

[ "$(uname -s)" = "Linux" ] || exit 0
command -v rpm >/dev/null 2>&1 || exit 0
command -v curl >/dev/null 2>&1 || exit 0

if command -v rpm-ostree >/dev/null 2>&1 && rpm-ostree status >/dev/null 2>&1; then
  installer=rpm-ostree
elif command -v dnf >/dev/null 2>&1; then
  installer=dnf
else
  exit 0
fi

if rpm -q --quiet "$package"; then
  echo "$package is already installed"
  exit 0
fi

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

curl -fsSL -o "$tmp" "$rpm_url"

case "$installer" in
  rpm-ostree)
    rpm-ostree install -y --idempotent "$tmp"
    ;;
  dnf)
    sudo dnf install -y "$tmp"
    ;;
esac
