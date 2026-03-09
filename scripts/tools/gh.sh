#!/usr/bin/env bash

# GitHub CLI installation script
#
# Linux (Fedora):
# - Installs GitHub CLI using shared Fedora host helper scripts.
#
# macOS:
# - GitHub CLI is expected to be managed by Brewfile.
# - This script provides guidance and verification only.

set -eu

abort() {
  printf "%s\n" "$*" >&2
  exit 1
}

if command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI is already installed."
  exit 0
fi

case "$(uname -s)" in
  Darwin)
    echo "Use Homebrew to install GitHub CLI on macOS"
    echo "brew install gh"
    ;;
  Linux)
    [ -f /etc/os-release ] || abort "Unsupported Linux distribution (missing /etc/os-release)"
    . /etc/os-release

    case "${ID:-}" in
      fedora)
        : "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../.." && pwd)}"
        bash "${DOTFILES_HOME}/host/os/fedora/repo.sh" \
          "https://cli.github.com/packages/rpm/gh-cli.repo" \
          "/etc/yum.repos.d/github-cli.repo"

        bash "${DOTFILES_HOME}/host/os/fedora/pkg.sh" install gh
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

echo "GitHub CLI (gh) installed"
