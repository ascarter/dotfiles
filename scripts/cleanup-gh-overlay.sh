#!/usr/bin/env bash

# One-off migration script: remove the legacy gh RPM overlay and repo
# from Fedora Atomic installs. Run once after deploying self-managed gh
# via `dotfiles tool install gh`, then delete this script.
#
# Usage:
#   dotfiles script cleanup-gh-overlay
#   # or directly:
#   bash scripts/cleanup-gh-overlay.sh

set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/.." && pwd)}"
source "${DOTFILES_HOME}/lib/logging.sh"

# Guard: only Fedora Atomic
if [[ "$(uname -s)" != Linux ]]; then
  log "cleanup" "not Linux — nothing to do"
  exit 0
fi

if [[ ! -f /etc/os-release ]]; then
  log "cleanup" "no /etc/os-release — nothing to do"
  exit 0
fi

. /etc/os-release

if [[ "${ID:-}" != fedora ]]; then
  log "cleanup" "not Fedora — nothing to do"
  exit 0
fi

case "${VARIANT_ID:-}" in
  silverblue|cosmic-atomic) ;;
  *)
    log "cleanup" "not Fedora Atomic (VARIANT_ID=${VARIANT_ID:-unknown}) — nothing to do"
    exit 0
    ;;
esac

# Remove gh rpm-ostree overlay (idempotent)
if rpm -q gh >/dev/null 2>&1; then
  log "cleanup" "removing gh rpm-ostree overlay"
  rpm-ostree uninstall gh
else
  log "cleanup" "gh package not in overlay — skipping"
fi

# Remove the GitHub CLI repo file
repo_file="/etc/yum.repos.d/github-cli.repo"
if [[ -f "$repo_file" ]]; then
  log "cleanup" "removing ${repo_file}"
  sudo rm -f "$repo_file"
else
  log "cleanup" "${repo_file} not found — skipping"
fi

success "Legacy gh overlay cleanup complete"
log "hint" "reboot to apply rpm-ostree changes, then verify: dotfiles tool install gh && gh --version"
