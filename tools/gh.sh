#!/usr/bin/env bash

# GitHub CLI installation script
#
# Linux (Fedora):
# - Installs GitHub CLI using shared Fedora lib helper scripts.
#
# macOS:
# - GitHub CLI is expected to be managed by Brewfile.
# - This script provides guidance and verification only.

set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/.." && pwd)}"
source "${DOTFILES_HOME}/lib/opt.sh"

if command -v gh >/dev/null 2>&1; then
  log "gh" "already installed: $(command -v gh)"
  exit 0
fi

case "$(uname -s)" in
  Darwin)
    log "gh" "not found. Run: brew install gh"
    exit 1
    ;;
  Linux)
    [ -f /etc/os-release ] || abort "Unsupported Linux distribution (missing /etc/os-release)"
    . /etc/os-release

    case "${ID:-}" in
      fedora)
        bash "${DOTFILES_HOME}/lib/os/fedora/repo.sh" \
          "https://cli.github.com/packages/rpm/gh-cli.repo" \
          "/etc/yum.repos.d/github-cli.repo"

        bash "${DOTFILES_HOME}/lib/os/fedora/pkg.sh" install gh
        ;;
      *)
        abort "Unsupported Linux distribution: ${ID:-unknown}"
        ;;
    esac
    ;;
  *)
    abort "Unsupported OS: $(uname -s)"
    ;;
esac

log "gh" "installed"
