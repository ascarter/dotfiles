#!/usr/bin/env bash

set -eu

: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../.." && pwd)}"
source "${DOTFILES_HOME}/lib/logging.sh"
source "${DOTFILES_HOME}/lib/checksum.sh"

# XDG defaults (set -u safe)
: "${XDG_BIN_HOME:=$HOME/.local/bin}"
: "${XDG_DATA_HOME:=$HOME/.local/share}"
: "${XDG_CACHE_HOME:=$HOME/.cache}"

GO_SDK_DIR="${XDG_DATA_HOME}/go-sdk"
GO_CACHE_DIR="${XDG_CACHE_HOME}/go-dl"
GO_LINK="${XDG_BIN_HOME}/go"
GOFMT_LINK="${XDG_BIN_HOME}/gofmt"

# Detect platform
go_os=""
go_arch=""
case "$(uname -s)" in
  Darwin) go_os="darwin" ;;
  Linux)  go_os="linux"  ;;
  *)      abort "Unsupported OS: $(uname -s)" ;;
esac
case "$(uname -m)" in
  aarch64|arm64) go_arch="arm64" ;;
  x86_64)        go_arch="amd64" ;;
  *)             abort "Unsupported architecture: $(uname -m)" ;;
esac

# Check if this script manages the current Go install
is_managed() {
  [[ -L "$GO_LINK" ]] && [[ "$(readlink "$GO_LINK")" == "${GO_SDK_DIR}"/* ]]
}

# If go exists but is NOT managed by us, leave it alone
if command -v go >/dev/null 2>&1 && ! is_managed; then
  log "go" "found system-managed Go ($(go version)), skipping"
  exit 0
fi

command -v curl >/dev/null 2>&1 || abort "curl is required"
command -v jq >/dev/null 2>&1 || abort "jq is required"

# Query go.dev for latest stable release
jq_filter='
  [.[] | select(.stable == true)][0].files[]
  | select(.os == $os and .arch == $arch and .kind == "archive"
           and (.filename | endswith(".tar.gz")))
  | [.filename, .sha256, .version]
  | @tsv'

go_meta=$(curl -fsSL "https://go.dev/dl/?mode=json") || abort "Failed to fetch Go release metadata"

read -r go_filename go_checksum go_version <<< \
  "$(printf '%s' "$go_meta" | jq -r \
    --arg os "$go_os" --arg arch "$go_arch" "$jq_filter")" \
  || abort "No matching stable release for ${go_os}/${go_arch}"

if [[ -z "${go_version:-}" || -z "${go_filename:-}" || -z "${go_checksum:-}" ]]; then
  abort "No matching stable release found for ${go_os}/${go_arch}"
fi

# Check if already at latest version
if is_managed && command -v go >/dev/null 2>&1; then
  current="$(go version | awk '{print $3}')"
  if [[ "$current" == "$go_version" ]]; then
    log "go" "${go_version} already installed"
    exit 0
  fi
  log "go" "updating ${current} -> ${go_version}"
else
  log "go" "installing ${go_version}"
fi

# Download
mkdir -p "$GO_CACHE_DIR"
log "go" "downloading ${go_filename}"
curl -fsSL -o "${GO_CACHE_DIR}/${go_filename}" "https://go.dev/dl/${go_filename}"

# Verify checksum
log "go" "verifying checksum"
sha256_verify "${GO_CACHE_DIR}/${go_filename}" "$go_checksum" \
  || { rm -f "${GO_CACHE_DIR}/${go_filename}"; abort "Checksum verification failed"; }

# Extract to staging dir, then swap atomically
staging="$(mktemp -d)"
trap 'rm -rf "$staging"' EXIT

log "go" "extracting"
tar -xzf "${GO_CACHE_DIR}/${go_filename}" -C "$staging"

# Validate extracted SDK
[[ -x "${staging}/go/bin/go" ]] || abort "Extracted SDK missing go binary"

# Swap into place
rm -rf "$GO_SDK_DIR"
mv "${staging}/go" "$GO_SDK_DIR"

# Symlink binaries
mkdir -p "$XDG_BIN_HOME"
ln -sf "${GO_SDK_DIR}/bin/go" "$GO_LINK"
ln -sf "${GO_SDK_DIR}/bin/gofmt" "$GOFMT_LINK"

# Clean up cached download
rm -f "${GO_CACHE_DIR}/${go_filename}"

log "go" "installed ${go_version}"
