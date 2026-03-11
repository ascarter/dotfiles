#!/usr/bin/env bash
set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/.." && pwd)}"
source "${DOTFILES_HOME}/lib/opt.sh"

if command -v go >/dev/null 2>&1; then
  echo "go already installed: $(command -v go)"
  exit 0
fi

# Requires curl and jq
command -v curl >/dev/null 2>&1 || { echo "curl is required" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "jq is required (install it first)" >&2; exit 1; }

# Map platform to Go naming conventions
case "$TOOLS_PLATFORM" in
  aarch64-darwin) GO_OS="darwin"; GO_ARCH="arm64"  ;;
  x86_64-darwin)  GO_OS="darwin"; GO_ARCH="amd64"  ;;
  aarch64-linux)  GO_OS="linux";  GO_ARCH="arm64"  ;;
  x86_64-linux)   GO_OS="linux";  GO_ARCH="amd64"  ;;
  *) echo "Unsupported platform: $TOOLS_PLATFORM" >&2; exit 1 ;;
esac

GO_EXT="tar.gz"
GO_RELEASES_URL="https://go.dev/dl/?mode=json"

# Query latest stable release
JQ_FILTER='
  .[0].files[]
  | select(.os == $os and .arch == $arch and (.filename | endswith($ext)))
  | [.filename, .sha256, .version]
  | @tsv'

read -r GO_FILENAME GO_CHECKSUM GO_VERSION <<< \
  "$(curl -fsSL "$GO_RELEASES_URL" | jq -r \
    --arg os "$GO_OS" --arg arch "$GO_ARCH" --arg ext "$GO_EXT" \
    "$JQ_FILTER")"

if [[ -z "${GO_VERSION:-}" || -z "${GO_FILENAME:-}" || -z "${GO_CHECKSUM:-}" ]]; then
  echo "No matching stable release found for ${GO_OS}/${GO_ARCH}" >&2
  exit 1
fi

TOOL_NAME="go"
STATE_FILE="${TOOLS_STATE}/${TOOL_NAME}"
INSTALL_DIR="${TOOLS_CELLAR}/${TOOL_NAME}/${GO_VERSION}"
CURRENT_LINK="${TOOLS_CELLAR}/${TOOL_NAME}/current"

# Check if already installed at this version
if [[ -f "$STATE_FILE" ]] && [[ "$(cat "$STATE_FILE")" == "$GO_VERSION" ]] && [[ -d "$INSTALL_DIR" ]]; then
  log "skip" "go already at ${GO_VERSION}"
  exit 0
fi

# Determine checksum command
if command -v shasum >/dev/null 2>&1; then
  SHASUM_CMD="shasum -a 256 -c"
elif command -v sha256sum >/dev/null 2>&1; then
  SHASUM_CMD="sha256sum -c"
else
  echo "shasum or sha256sum is required" >&2
  exit 1
fi

# Download
CACHE_DIR="${TOOLS_CACHE}/${TOOL_NAME}"
mkdir -p "$CACHE_DIR"

log "download" "go ${GO_VERSION} (${GO_OS}/${GO_ARCH})"
curl -fsSL -o "${CACHE_DIR}/${GO_FILENAME}" "https://go.dev/dl/${GO_FILENAME}"

# Verify checksum
log "verify" "checksum"
echo "${GO_CHECKSUM}  ${CACHE_DIR}/${GO_FILENAME}" | $SHASUM_CMD >/dev/null 2>&1 || {
  error "Checksum verification failed"
  rm -f "${CACHE_DIR}/${GO_FILENAME}"
  exit 1
}

# Clean previous version if present
if [[ -d "$INSTALL_DIR" ]]; then
  rm -rf "$INSTALL_DIR"
fi

# Extract (tarball contains a top-level go/ directory; strip it)
mkdir -p "$INSTALL_DIR"
log "extract" "${GO_FILENAME}"
tar -xzf "${CACHE_DIR}/${GO_FILENAME}" -C "$INSTALL_DIR" --strip-components=1

# Point current symlink to this version
ln -sfn "$INSTALL_DIR" "$CURRENT_LINK"

# Record installed version
printf '%s\n' "$GO_VERSION" > "$STATE_FILE"

log "install" "go ${GO_VERSION} -> ${INSTALL_DIR}"
echo "go installed: ${CURRENT_LINK}/bin/go"
