#!/bin/sh

set -eu

MISE_BIN="${MISE_BIN:-${XDG_BIN_HOME:-${HOME}/.local/bin}/mise}"
MISE_CONFIG_DIR="${MISE_CONFIG_DIR:-${XDG_CONFIG_HOME:-${HOME}/.config}/mise}"

export MISE_CONFIG_DIR

log() {
  printf 'uninstall: %s\n' "$*"
}

fail() {
  log "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage: uninstall.sh [-n|--dry-run] [-y|--yes]

Unapply dotfiles and use `mise implode` to remove mise while preserving the
global configuration checkout.

Options:
  -n, --dry-run  Preview every removal without applying it
  -y, --yes      Skip this script's confirmation prompt
  -h, --help     Show this help
EOF
}

confirm_uninstall() {
  printf 'Unapply dotfiles and permanently remove mise? [y/N] ' >/dev/tty
  IFS= read -r answer </dev/tty || answer=
  case "$answer" in
    y | Y | yes | YES | Yes) return 0 ;;
    *) return 1 ;;
  esac
}

dry_run=false
assume_yes=false
for option in "$@"; do
  case "$option" in
    --dry-run | -n) dry_run=true ;;
    --yes | -y) assume_yes=true ;;
    --help | -h)
      usage
      exit 0
      ;;
    *) fail "unsupported option: $option" ;;
  esac
done

[ -x "$MISE_BIN" ] || fail "mise is not installed at $MISE_BIN"

if [ "$dry_run" = false ] && [ "$assume_yes" = false ]; then
  confirm_uninstall || {
    log "Uninstall cancelled."
    exit 0
  }
  set -- "$@" --yes
fi

log "mise dotfile removal"
"$MISE_BIN" bootstrap dotfiles unapply "$@"

log "mise implode"
"$MISE_BIN" implode "$@"

log "Uninstall complete."
log "Configuration checkout preserved at $MISE_CONFIG_DIR."
log "Restart session to discard the current shell environment."
