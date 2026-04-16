#!/usr/bin/env bash

# Speedtest CLI
#
# macOS: installed via Homebrew (brew tap teamookla/speedtest && brew install speedtest)
# Linux: direct tarball download from Ookla

set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../.." && pwd)}"
source "${DOTFILES_HOME}/lib/logging.sh"
source "${DOTFILES_HOME}/lib/checksum.sh"

SPEEDTEST_VERSION="1.2.0"

if command -v speedtest >/dev/null 2>&1; then
  log "speedtest" "already installed: $(command -v speedtest)"
  exit 0
fi

case "$(uname -s)" in
  Darwin)
    log "speedtest" "install via: brew tap teamookla/speedtest && brew install speedtest"
    exit 0
    ;;
  Linux) ;;
  *) abort "Unsupported OS: $(uname -s)" ;;
esac

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64)  SPEEDTEST_ARCH="linux-x86_64" ;;
  aarch64) SPEEDTEST_ARCH="linux-aarch64" ;;
  *) abort "Unsupported architecture: $ARCH" ;;
esac

: "${XDG_BIN_HOME:=$HOME/.local/bin}"
: "${XDG_DATA_HOME:=$HOME/.local/share}"
: "${XDG_CACHE_HOME:=$HOME/.cache}"

DOWNLOAD_DIR="${XDG_CACHE_HOME}/speedtest"
INSTALL_DIR="${XDG_DATA_HOME}/speedtest"
TARBALL="ookla-speedtest-${SPEEDTEST_VERSION}-${SPEEDTEST_ARCH}.tgz"
URL="https://install.speedtest.net/app/cli/${TARBALL}"

mkdir -p "$DOWNLOAD_DIR" "$INSTALL_DIR" "$XDG_BIN_HOME"

log "speedtest" "Downloading ${TARBALL}"
curl -fsSL -o "${DOWNLOAD_DIR}/${TARBALL}" "$URL" || abort "Failed to download speedtest"

log "speedtest" "Extracting to ${INSTALL_DIR}"
tar -xzf "${DOWNLOAD_DIR}/${TARBALL}" -C "$INSTALL_DIR" || abort "Failed to extract speedtest"

ln -sfn "${INSTALL_DIR}/speedtest" "${XDG_BIN_HOME}/speedtest"

# Install man page if available
if [ -f "${INSTALL_DIR}/speedtest.5" ]; then
  MAN_DIR="${XDG_DATA_HOME}/man/man5"
  mkdir -p "$MAN_DIR"
  cp "${INSTALL_DIR}/speedtest.5" "$MAN_DIR/"
fi

log "speedtest" "installed (v${SPEEDTEST_VERSION})"
