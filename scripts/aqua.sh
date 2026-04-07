#!/usr/bin/env bash

# Install aqua via the official aqua-installer with checksum verification.
#
# Downloads the installer to a temp file, verifies its SHA256 checksum,
# and only executes if the checksum matches. Cleans up the temp file on exit.

set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/.." && pwd)}"
source "${DOTFILES_HOME}/lib/logging.sh"

if command -v aqua >/dev/null 2>&1; then
  log "aqua" "Already installed, skipping"
  exit 0
fi

tmpfile="$(mktemp)"
cleanup() { rm -f "$tmpfile"; }
trap cleanup EXIT

INSTALLER_VERSION="v4.0.4"
INSTALLER_SHA256="acd21cbb06609dd9a701b0032ba4c21fa37b0e3b5cc4c9d721cc02f25ea33a28"
INSTALLER_URL="https://raw.githubusercontent.com/aquaproj/aqua-installer/${INSTALLER_VERSION}/aqua-installer"

log "aqua" "Downloading aqua-installer ${INSTALLER_VERSION}"
curl -sSfL -o "$tmpfile" "$INSTALLER_URL"

log "aqua" "Verifying checksum"
echo "${INSTALLER_SHA256}  ${tmpfile}" | shasum -a 256 -c - >/dev/null
log "aqua" "Checksum verified"

log "aqua" "Running installer"
bash "$tmpfile"

log "aqua" "Installed successfully"
