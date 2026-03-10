#!/usr/bin/env bash

# Fedora repository management helper.
#
# Intended entrypoint:
#   bash "${DOTFILES_LIB_DIR}/os/fedora/repo.sh" <repo_url> <repo_path>
#
# Example:
#   bash "${DOTFILES_LIB_DIR}/os/fedora/repo.sh" \
#     "https://cli.github.com/packages/rpm/gh-cli.repo" \
#     "/etc/yum.repos.d/github-cli.repo"

set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../../.." && pwd)}"
source "${DOTFILES_HOME}/lib/core.sh"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || abort "Missing required command: $1"
}

[ "$(uname -s)" = "Linux" ] || abort "Unsupported OS: $(uname -s)"
[ -f /etc/os-release ] || abort "Unsupported Linux distribution (missing /etc/os-release)"
. /etc/os-release
[ "${ID:-}" = "fedora" ] || abort "Unsupported Linux distribution: ${ID:-unknown}"

REPO_URL="${1:-}"
REPO_PATH="${2:-}"

[ -n "$REPO_URL" ]  || abort "Usage: bash \"\${DOTFILES_LIB_DIR}/os/fedora/repo.sh\" <repo_url> <repo_path>"
[ -n "$REPO_PATH" ] || abort "Usage: bash \"\${DOTFILES_LIB_DIR}/os/fedora/repo.sh\" <repo_url> <repo_path>"

case "$REPO_PATH" in
  /etc/yum.repos.d/*.repo) ;;
  *) abort "Repository path must be under /etc/yum.repos.d and end with .repo: $REPO_PATH" ;;
esac

require_cmd curl
require_cmd sudo
require_cmd tee

if [ -f "$REPO_PATH" ]; then
  log "repo" "already present: $REPO_PATH"
  exit 0
fi

log "repo" "Adding: $REPO_PATH"
curl -fsSL "$REPO_URL" | sudo tee "$REPO_PATH" >/dev/null
log "repo" "Added: $REPO_PATH"
