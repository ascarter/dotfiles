#!/bin/sh

set -eu

readonly DEFAULT_REPO_URL="https://github.com/ascarter/dotfiles.git"
readonly REPO_DIR="${HOME}/Developer/dotfiles"
readonly MISE_BIN="${HOME}/.local/bin/mise"
readonly MISE_CONFIG="${REPO_DIR}/mise.toml"

log() {
  printf 'bootstrap: %s\n' "$*"
}

fail() {
  log "$*" >&2
  exit 1
}

require_commands() {
  for command_name in "$@"; do
    command -v "$command_name" >/dev/null 2>&1 ||
      fail "$command_name is required"
  done
}

ensure_checkout() {
  if [ -f "$MISE_CONFIG" ]; then
    return 0
  fi

  if [ -e "$REPO_DIR" ] && [ ! -d "$REPO_DIR" ]; then
    fail "$REPO_DIR exists but is not a directory"
  fi

  if [ -d "$REPO_DIR" ] && [ -n "$(find "$REPO_DIR" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]; then
    fail "$REPO_DIR exists but is not a dotfiles checkout"
  fi

  log "Cloning dotfiles into $REPO_DIR"
  mkdir -p "$(dirname "$REPO_DIR")"
  git clone "$repo_url" "$REPO_DIR"
}

install_mise() {
  if [ -x "$MISE_BIN" ]; then
    return 0
  fi

  log "Installing mise at $MISE_BIN"
  mkdir -p "$(dirname "$MISE_BIN")"
  curl -fsSL https://mise.run | MISE_INSTALL_PATH="$MISE_BIN" sh
  [ -x "$MISE_BIN" ] || fail "mise installation did not create $MISE_BIN"
}

require_commands curl git /bin/zsh

repo_url=${DOTFILES_REPO_URL:-$DEFAULT_REPO_URL}
ensure_checkout
install_mise

"$MISE_BIN" trust "$MISE_CONFIG"

log "Delegating machine setup to mise"
exec "$MISE_BIN" -C "$REPO_DIR" bootstrap "$@"
