#!/bin/sh

# GitHub CLI installation script
#
# Linux (Fedora):
# - Installs GitHub CLI using the official GitHub CLI repository.
# - Handles mutable Fedora and Fedora Atomic variants.
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
        GH_REPO_URL="https://cli.github.com/packages/rpm/gh-cli.repo"
        GH_REPO_PATH="/etc/yum.repos.d/github-cli.repo"
        if [ ! -f "$GH_REPO_PATH" ]; then
          curl -fsSL "$GH_REPO_URL" | sudo tee "$GH_REPO_PATH"
        fi

        case "${VARIANT_ID}" in
          silverblue|cosmic-atomic)
            rpm-ostree refresh-md
            rpm-ostree install --idempotent gh
            ;;
          *)
            sudo dnf makecache --refresh
            sudo dnf install -y gh
            ;;
        esac
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
