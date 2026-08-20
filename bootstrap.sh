#!/bin/sh

set -eu

readonly DOTFILES_REPO_URL="https://github.com/ascarter/dotfiles.git"
readonly DOTFILES_HOME="${HOME}/.dotfiles"
readonly MISE_BIN="${HOME}/.local/bin/mise"

# Enable auto_env for mise to support platform environment detection
readonly MISE_AUTO_ENV=true

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

confirm_install() {
  prompt="$1"
  response=""

  printf 'bootstrap: %s [y/N] ' "$prompt" >&2
  if [ -r /dev/tty ]; then
    IFS= read -r response </dev/tty || true
  else
    IFS= read -r response || true
  fi

  case "$response" in
    [yY] | [yY][eE][sS]) return 0 ;;
    *) return 1 ;;
  esac
}

install_prerequisites() {
  missing_commands=""

  for command_name in curl git; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
      missing_commands="${missing_commands:+$missing_commands }$command_name"
    fi
  done

  [ -z "$missing_commands" ] && return 0

  case "$(uname -s)" in
    Darwin)
      if ! confirm_install "Missing $missing_commands. Install Xcode Command Line Tools?"; then
        fail "curl and git are required"
      fi

      require_commands xcode-select
      log "Requesting the Xcode Command Line Tools installer"
      xcode-select --install || fail "Unable to start the Xcode Command Line Tools installer"
      fail "Complete the Xcode Command Line Tools installation, then rerun bootstrap"
      ;;
    Linux)
      if [ ! -r /etc/os-release ]; then
        fail "curl and git are required; unable to identify this Linux distribution"
      fi

      # shellcheck disable=SC1091
      . /etc/os-release
      case "${ID:-}" in
        fedora)
          installer="dnf install -y"
          ;;
        ubuntu | debian)
          installer="apt-get install -y"
          ;;
        arch)
          installer="pacman -S --needed --noconfirm"
          ;;
        *)
          fail "curl and git are required; install with package manager and rerun bootstrap"
          ;;
      esac

      if ! confirm_install "Missing $missing_commands. Install with $installer?"; then
        fail "curl and git are required"
      fi

      require_commands sudo
      log "Installing $missing_commands"
      # Deliberately expand the selected, fixed package-manager command here.
      # shellcheck disable=SC2086
      sudo $installer $missing_commands
      ;;
    *)
      fail "curl and git are required; install with package manager and rerun bootstrap"
      ;;
  esac
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
  [ -x "$MISE_BIN" ] || fail "mise installation did not create $MISE_BIN"
}

install_prerequisites
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
