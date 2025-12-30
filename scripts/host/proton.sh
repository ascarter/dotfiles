#!/bin/sh

# Proton Mail / Pass / Authenticator installation script for Fedora Silverblue
# Layers Proton RPMs via rpm-ostree
# References:
# 1. https://proton.me/support/linux-mail-desktop
# 2. https://proton.me/support/linux-authenticator-desktop
# 3. https://proton.me/support/linux-pass-desktop

set -eu

abort() {
  printf "%s\n" "$*" >&2
  exit 1
}

sha512_verify_file() {
  file="$1"
  expected_sha512="$2"
  echo "${expected_sha512}  ${file}" | sha512sum --check - >/dev/null 2>&1
}

cache_rm() {
  file="$1"
  if [ -f "$file" ]; then
    echo "Removing cached file: $file"
    rm -f "$file"
  fi
}

get_release() {
  manifest_url=$1
  category=$2
  identifier=$3

  # Pick "latest stable" entry from Proton's JSON.
  # Proton version manifests (contain latest URLs + SHA512)
  # Pick latest Stable release by semantic version, then select matching identifier
  # Extract URL + SHA512 in one jq run as tab-separated fields.
  query='
    def semver_key:
      ( .Version
        | split(".")
        | map(tonumber)
        | . + ([0,0,0])[0:3]
        | .[0:3]
      );

    .Releases
    | map(select(.CategoryName == $category))
    | max_by(semver_key)
    | .File
    | map(select(.Identifier == $id))
    | first
    | select(. != null)
    | [.Url, .Sha512CheckSum]
    | @tsv
  '
  curl -fsSL "$manifest_url" | jq -r --arg category "$category" --arg id "$identifier" "$query"
}

proton_rpm() {
  CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/proton-rpms"
  mkdir -p "$CACHE_DIR"

  for cmd in curl jq sha512sum rpm rpm-ostree; do
    command -v "$cmd" >/dev/null 2>&1 || abort "Missing command '$cmd'"
  done

  rpm_repo_setup() {
    repo_url="$1"
    repo_path="$2"

    if [ ! -f "/etc/yum.repos.d/${repo_path}" ]; then
      echo "Installing ProtonVPN repository"
      rpm_install "${repo_url}"

      case "$VARIANT_ID" in
        silverblue | cosmic-atomic)
          rpm-ostree refresh-md
          return 1
          ;;
        *)
          sudo dnf check-update --refresh
          ;;
      esac
    fi
  }

  rpm_install() {
    rpm_file="$1"
    case "$VARIANT_ID" in
      silverblue | cosmic-atomic)
        rpm-ostree install --idempotent "$rpm_file"
        ;;
      *)
        sudo dnf install -y "$rpm_file"
        ;;
    esac
  }

  update_icons() {
    user_icon_dir="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor"
    user_scalable_icon_dir="${user_icon_dir}/scalable/apps"

    # Fix up pixmaps icons
    mkdir -p "$user_scalable_icon_dir"
    for icon in /usr/share/pixmaps/proton-*.png; do
      icon_name=$(basename "$icon" .png)
      user_icon_file="${user_scalable_icon_dir}/${icon_name}.svg"
      if [ -f "$user_icon_file" ]; then
        continue
      fi
      echo "Installing icon: ${icon_name}"
      cp "${icon}" "${user_icon_file}"
    done
  }

  rpm_app_install() {
    manifest_url="$1"

    category="Stable"
    identifier=".rpm (Fedora/RHEL)"

    tsv=$(get_release "$manifest_url" "$category" "$identifier") || abort "Failed to get release info from $manifest_url"
    rpm_url=$(echo "$tsv" | cut -f1)
    sha512=$(echo "$tsv" | cut -f2)
    rpm_file="${CACHE_DIR}/$(basename "$rpm_url")"

    # If the RPM is already present and matches the expected SHA512, reuse it.
    if [ -f "$rpm_file" ]; then
      if sha512_verify_file "$rpm_file" "$sha512"; then
        echo "Using cached RPM: $rpm_file"
      else
        # Invalidate bad cache package
        echo "Checksum mismatch" >&2
        cache_rm "$rpm_file"
      fi
    fi

    if ! [ -f "$rpm_file" ]; then
      curl -fsSL "$rpm_url" -o "$rpm_file"
      if ! sha512_verify_file "$rpm_file" "$sha512"; then
        echo "Checksum mismatch" >&2
        cache_rm "$rpm_file"
        return 1
      fi
    fi

    # Get NEVR from the RPM payload
    pkg_name="$(rpm -qp --queryformat '%{NAME}\n' "$rpm_file")"
    pkg_verrel="$(rpm -qp --queryformat '%{VERSION}-%{RELEASE}\n' "$rpm_file")"

    installed_verrel="(not installed)"
    if rpm -q "$pkg_name" >/dev/null 2>&1; then
      installed_verrel="$(rpm -q --qf '%{VERSION}-%{RELEASE}\n' "$pkg_name" || true)"
    fi

    if [ "$installed_verrel" = "$pkg_verrel" ]; then
      echo "Up to date: ${pkg_name} ${installed_verrel}"
      return 0
    fi

    rpm_install "$rpm_file"
  }

  proton_vpn_repo="https://repo.protonvpn.com/fedora-${VERSION_ID}-stable/protonvpn-stable-release/protonvpn-stable-release-1.0.3-1.noarch.rpm"
  rpm_repo_setup "$proton_vpn_repo" "protonvpn-stable.repo" || {
    echo "Reboot to complete repository setup:"
    echo "  systemctl reboot"
    exit 0
  }

  rpm_install proton-vpn-gnome-desktop
  rpm_install proton-vpn-cli

  rpm_app_install "https://proton.me/download/authenticator/linux/version.json"
  rpm_app_install "https://proton.me/download/mail/linux/version.json"
  rpm_app_install "https://proton.me/download/PassDesktop/linux/x64/version.json"

  update_icons
}

case "$(uname -s)" in
  Linux)
    if [ -f /etc/os-release ]; then
      . /etc/os-release
      case "${ID}" in
        fedora)
          proton_rpm
          ;;
        *)
          abort "Unsupported Linux distribution: ${ID}"
          ;;
      esac
    else
      abort "Unsupported Linux distribution"
    fi
    ;;
  *)
    abort "Unsupported OS: $(uname -s)"
    ;;
esac
