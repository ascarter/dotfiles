#!/bin/sh

set -eu

readonly BOOTSTRAP_REPO_URL="https://github.com/ascarter/dotfiles.git"
MISE_BIN="${MISE_BIN:-${XDG_BIN_HOME:-${HOME}/.local/bin}/mise}"
MISE_CONFIG_DIR="${MISE_CONFIG_DIR:-${XDG_CONFIG_HOME:-${HOME}/.config}/mise}"

export MISE_AUTO_ENV=true
export MISE_ENV_CONF_D=true
export MISE_CONFIG_DIR

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

install_mise() {
  if [ -x "$MISE_BIN" ]; then
    log "Updating mise at $MISE_BIN"
    "$MISE_BIN" self-update --yes
  else
    log "Installing mise at $MISE_BIN"
    mkdir -p "$(dirname "$MISE_BIN")"
    curl -fsSL https://mise.run | MISE_INSTALL_PATH="$MISE_BIN" sh
    [ -x "$MISE_BIN" ] || fail "mise installation failed"
  fi
}

require_commands curl git

install_mise

log "Running mise bootstrap"
# Keep prompts interactive when the script itself is being read from a pipe.
if { exec 3</dev/tty; } 2>/dev/null; then
  :
else
  exec 3<&0
fi
"$MISE_BIN" bootstrap --from-git "$BOOTSTRAP_REPO_URL" "$@" <&3
