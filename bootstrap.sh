#!/bin/sh

set -eu

readonly DOTFILES_REPO_URL="https://github.com/ascarter/dotfiles.git"
readonly DOTFILES_HOME="${HOME}/.dotfiles"
readonly MISE_BIN="${HOME}/.local/bin/mise"

export MISE_AUTO_ENV=true

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

checkout() {
  local repo_url="$1"
  local checkout_dir="$2"

	if [ -e "$checkout_dir" ] && [ ! -d "$checkout_dir" ]; then
		fail "$checkout_dir exists but is not a directory"
	fi

	if [ -d "$checkout_dir" ]; then
		if checkout_root="$(git -C "$checkout_dir" rev-parse --show-toplevel 2>/dev/null)" &&
			[ "$checkout_root" = "$checkout_dir" ]; then
			log "Dotfiles checkout exists at $checkout_dir"
			return 0
		fi

		if [ -n "$(find "$checkout_dir" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]; then
			fail "$checkout_dir exists but is not a dotfiles checkout"
		fi
	fi

  log "Cloning dotfiles into $checkout_dir"
  mkdir -p "$(dirname "$checkout_dir")"
  git clone "$repo_url" "$checkout_dir" || fail "Failed to clone $repo_url into $checkout_dir"
}

install_mise() {
  if [ -x "$MISE_BIN" ]; then
    return 0
  fi

  log "Installing mise at $MISE_BIN"
  mkdir -p "$(dirname "$MISE_BIN")"
  curl -fsSL https://mise.run | MISE_INSTALL_PATH="$MISE_BIN" sh
  [ -x "$MISE_BIN" ] || fail "mise installation failed"
}

require_commands curl git

checkout ${DOTFILES_REPO_URL} ${DOTFILES_HOME}
install_mise
"$MISE_BIN" -C "$DOTFILES_HOME" trust

log "Running mise bootstrap in $DOTFILES_HOME"
# Keep prompts interactive when the script itself is being read from a pipe.
if { exec 3</dev/tty; } 2>/dev/null; then
  :
else
  exec 3<&0
fi
"$MISE_BIN" -C "$DOTFILES_HOME" bootstrap "$@" <&3
