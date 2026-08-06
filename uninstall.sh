#!/bin/sh

set -eu

readonly MISE_BIN="${HOME}/.local/bin/mise"

dry_run=false
assume_yes=false

log() {
  printf 'uninstall: %s\n' "$*"
}

fail() {
  log "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage: uninstall.sh [--dry-run] [--yes]

Unapply dotfiles and use `mise implode` to remove mise.

Options:
  --dry-run  Preview every removal without applying it
  --yes      Skip this script's confirmation prompt
  -h, --help Show this help
EOF
}

confirm_uninstall() {
  if ! has_terminal; then
    fail "confirmation needs a terminal; rerun with --dry-run or --yes"
  fi

  printf 'Unapply dotfiles and permanently remove mise? [y/N] ' >/dev/tty
  IFS= read -r answer </dev/tty || answer=
  case "$answer" in
    y | Y | yes | YES | Yes) return 0 ;;
    *) return 1 ;;
  esac
}

require_commands() {
  for command_name in "$@"; do
    command -v "$command_name" >/dev/null 2>&1 ||
      fail "$command_name is required"
  done
}

run_mise() {
  exec "$MISE_BIN" -C "$DOTFILES_HOME" "$@" || fail "mise failed: $*"
}

require_commands mise git

log "Previewing managed dotfile removal"
"$MISE_BIN" bootstrap dotfiles unapply "$@"

log "Previewing mise removal"
"$MISE_BIN" implode "$@"

# `mise implode` preserves its config directory by default. Remove it only
# when dotfile unapply left it empty; preserve any local configuration files.
rmdir "$HOME/.config/mise" 2>/dev/null || true

log "Uninstall complete."
log "Restart session to discard the current shell environment."
