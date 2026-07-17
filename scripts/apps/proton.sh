#!/usr/bin/env bash

# Proton Mail / Pass / Drive / Authenticator installation script
# Layers Proton RPMs via rpm-ostree on Fedora Atomic
# References:
# 1. https://proton.me/support/linux-mail-desktop
# 2. https://proton.me/support/linux-authenticator-desktop
# 3. https://proton.me/support/linux-pass-desktop
# 4. https://proton.me/support/drive-cli

set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../.." && pwd)}"
source "${DOTFILES_HOME}/lib/logging.sh"

: "${XDG_BIN_HOME:=$HOME/.local/bin}"
: "${XDG_CACHE_HOME:=$HOME/.cache}"

sha512_verify_file() {
  local file="$1"
  local expected_sha512="$2"

  if command -v sha512sum >/dev/null 2>&1; then
    echo "${expected_sha512}  ${file}" | sha512sum --check - >/dev/null 2>&1
  elif command -v shasum >/dev/null 2>&1; then
    echo "${expected_sha512}  ${file}" | shasum -a 512 --check - >/dev/null 2>&1
  else
    abort "No SHA-512 tool found (need sha512sum or shasum)"
  fi
}

cache_rm() {
  file="$1"
  if [ -f "$file" ]; then
    log "proton" "Removing cached file: $file"
    rm -f "$file"
  fi
}

get_release() {
  local manifest_url=$1
  local category=$2
  local identifier=$3

  # Pick latest entry from Proton's JSON.
  # Proton version manifests (contain latest URLs + SHA512)
  # Pick latest Stable release by semantic version, then select matching identifier
  # Extract URL + SHA512 in one jq run as tab-separated fields.
  local query='
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
    | map(select(.Identifier | contains($id)))
    | first
    | select(. != null)
    | [.Url, .Sha512CheckSum]
    | @tsv
  '
  curl -fsSL "$manifest_url" | jq -r --arg category "$category" --arg id "$identifier" "$query"
}

get_drive_cli_release() {
  local platform="$1"
  local manifest_url="https://proton.me/download/drive/cli/version.json"
  local manifest
  manifest=$(curl -fsSL "$manifest_url") || return 1

  local query='
    def semver_key:
      ( .Version
        | split(".")
        | map(tonumber)
        | . + ([0,0,0])[0:3]
        | .[0:3]
      );

    .Releases
    | map(select(.CategoryName == "Stable"))
    | max_by(semver_key)
    | . as $release
    | .Files
    | map(select(.Platform == $platform))
    | first
    | select(. != null)
    | [$release.Version, .Url, .Sha512CheckSum]
    | @tsv
  '
  printf '%s' "$manifest" | jq -er --arg platform "$platform" "$query"
}

proton_drive_cli() {
  for cmd in curl install jq; do
    command -v "$cmd" >/dev/null 2>&1 || abort "Missing command '$cmd'"
  done

  local platform
  case "$(uname -s)/$(uname -m)" in
    Darwin/arm64 | Darwin/aarch64) platform="macos/arm64" ;;
    Darwin/x86_64)                platform="macos/x64" ;;
    Linux/aarch64 | Linux/arm64)  platform="linux/arm64" ;;
    Linux/x86_64)                 platform="linux/x64" ;;
    *) abort "Unsupported Proton Drive CLI platform: $(uname -s)/$(uname -m)" ;;
  esac

  local tsv
  tsv=$(get_drive_cli_release "$platform") ||
    abort "Failed to get Proton Drive CLI release for $platform"

  local version download_url sha512
  version=$(printf '%s' "$tsv" | cut -f1)
  download_url=$(printf '%s' "$tsv" | cut -f2)
  sha512=$(printf '%s' "$tsv" | cut -f3)

  local cache_dir="${XDG_CACHE_HOME}/proton-drive-cli/${version}/${platform/\//-}"
  local cached_file="${cache_dir}/proton-drive"
  local installed_file="${XDG_BIN_HOME}/proton-drive"

  if [ -f "$installed_file" ] && sha512_verify_file "$installed_file" "$sha512"; then
    log "proton-drive" "Up to date: ${version}"
    return
  fi

  mkdir -p "$cache_dir"
  if [ -f "$cached_file" ] && ! sha512_verify_file "$cached_file" "$sha512"; then
    error "Checksum mismatch"
    cache_rm "$cached_file"
  fi

  if [ ! -f "$cached_file" ]; then
    log "proton-drive" "Downloading ${version} for ${platform}"
    curl -fsSL "$download_url" -o "$cached_file" ||
      abort "Failed to download Proton Drive CLI from $download_url"
    if ! sha512_verify_file "$cached_file" "$sha512"; then
      error "Checksum mismatch"
      cache_rm "$cached_file"
      abort "Failed to verify Proton Drive CLI"
    fi
  fi

  install -d "$XDG_BIN_HOME"
  install -m 0755 "$cached_file" "$installed_file"
  log "proton-drive" "Installed: ${version}"
}

proton_rpm() {
  CACHE_DIR="${XDG_CACHE_HOME}/proton-rpms"
  mkdir -p "$CACHE_DIR"

  for cmd in curl jq sha512sum rpm rpm-ostree; do
    command -v "$cmd" >/dev/null 2>&1 || abort "Missing command '$cmd'"
  done

  rpm_repo_setup() {
    local repo_url="$1"
    local repo_path="$2"

    if [ ! -f "/etc/yum.repos.d/${repo_path}" ]; then
      log "proton" "Installing ProtonVPN repository"
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
    local rpm_file="$1"
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
    user_icon_dir="${XDG_DATA_HOME}/icons/hicolor"
    user_scalable_icon_dir="${user_icon_dir}/scalable/apps"

    # Fix up pixmaps icons
    install -d "$user_scalable_icon_dir"
    for icon in /usr/share/pixmaps/proton-*.png; do
      icon_name=$(basename "$icon" .png)
      user_icon_file="${user_scalable_icon_dir}/${icon_name}.svg"
      if [ -f "$user_icon_file" ]; then
        continue
      fi
      log "proton" "Installing icon: ${icon_name}"
      install -m 0644 "${icon}" "${user_icon_file}"
    done
  }

  rpm_download() {
    local rpm_url="$1"
    local sha512="$2"
    local rpm_file="$3"

    # If the RPM is already present and matches the expected SHA512, reuse it.
    if [ -f "$rpm_file" ]; then
      if sha512_verify_file "$rpm_file" "$sha512"; then
        vlog "proton" "Using cached RPM: $rpm_file"
        return
      else
        # Invalidate bad cache package
        error "Checksum mismatch"
        cache_rm "$rpm_file"
      fi
    fi

    if ! [ -f "$rpm_file" ]; then
      curl -fsSL "$rpm_url" -o "$rpm_file" || return 1
      if ! sha512_verify_file "$rpm_file" "$sha512"; then
        error "Checksum mismatch"
        cache_rm "$rpm_file"
        return 1
      fi
    fi
  }

  rpm_release_install() {
    local manifest_url="$1"
    local category="${2:-Stable}"
    local identifier=".rpm"

    local tsv
    tsv=$(get_release "$manifest_url" "$category" "$identifier") || abort "Failed to get release info from $manifest_url"
    local rpm_url sha512
    rpm_url=$(echo "$tsv" | cut -f1)
    sha512=$(echo "$tsv" | cut -f2)
    rpm_app_install "$rpm_url" "$sha512"
  }

  rpm_app_install() {
    local rpm_url="$1"
    local sha512="${2:-}"
    local rpm_file="${CACHE_DIR}/$(basename "$rpm_url")"

    rpm_download "$rpm_url" "$sha512" "$rpm_file" || abort "Failed to download or verify RPM from $rpm_url"

    # Get NEVR from the RPM payload
    local pkg_name pkg_verrel
    pkg_name="$(rpm -qp --queryformat '%{NAME}\n' "$rpm_file")"
    pkg_verrel="$(rpm -qp --queryformat '%{VERSION}-%{RELEASE}\n' "$rpm_file")"

    local installed_verrel="(not installed)"
    if rpm -q "$pkg_name" >/dev/null 2>&1; then
      installed_verrel="$(rpm -q --qf '%{VERSION}-%{RELEASE}\n' "$pkg_name" || true)"
    fi

    if [ "$installed_verrel" = "$pkg_verrel" ]; then
      log "proton" "Up to date: ${pkg_name} ${installed_verrel}"
      return 0
    fi

    # Ensure we don't have a previous version requested before installing the new RPM.
    case "$VARIANT_ID" in
      silverblue | cosmic-atomic)
        rpm-ostree uninstall --idempotent "$pkg_name" >/dev/null 2>&1 || true
        ;;
    esac

    rpm_install "$rpm_file"
  }

  proton_vpn_repo="https://repo.protonvpn.com/fedora-${VERSION_ID}-stable/protonvpn-stable-release/protonvpn-stable-release-1.0.3-1.noarch.rpm"
  rpm_repo_setup "$proton_vpn_repo" "protonvpn-stable.repo" || {
    warn "proton" "Reboot to complete repository setup"
    warn "proton" "Run: systemctl reboot"
    exit 0
  }

  rpm_install proton-vpn-gnome-desktop
  rpm_install proton-vpn-cli

  rpm_release_install "https://proton.me/download/authenticator/linux/version.json"
  rpm_release_install "https://proton.me/download/mail/linux/version.json"
  rpm_release_install "https://proton.me/download/PassDesktop/linux/x64/version.json"
  rpm_release_install "https://proton.me/download/meet/linux/version.json"
  rpm_app_install "https://proton.me/download/bridge/protonmail-bridge-3.21.2-1.x86_64.rpm" "e802d0a9630d4aaf2f32de1e0d5b350728476340746b6735fa4ea166595c7a688e3025497c3c20dda1b556bd6045f129275539601828091fbb43766a91bbeba4"
  update_icons
}

proton_pass_cli() {
  if command -v pass-cli >/dev/null 2>&1; then
    log "pass-cli" "Updating"
    pass-cli update
  else
    log "pass-cli" "Installing"
    curl -fsSL https://proton.me/download/pass-cli/install.sh | bash
  fi
}

case "$(uname -s)" in
  Darwin)
    proton_drive_cli
    proton_pass_cli

    log "proton" "Proton apps are managed via Homebrew casks on macOS"
    log "proton" "Run: brew bundle --global"
    log "proton" "Or install individually:"
    for cask in proton-drive proton-mail proton-mail-bridge proton-pass protonvpn; do
      log "proton" "  brew install --cask ${cask}"
    done
    ;;
  Linux)
    if [ -f /etc/os-release ]; then
      . /etc/os-release
      case "${ID}" in
        fedora)
          proton_drive_cli
          proton_pass_cli
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
