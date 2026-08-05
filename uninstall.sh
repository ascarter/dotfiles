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

Unapply this repository's dotfiles, remove mise-owned GitHub credential-helper
entries, and use `mise implode` to remove mise and its installed tools and data.

Options:
  --dry-run  Preview every removal without applying it
  --yes      Skip this script's confirmation prompt
  -h, --help Show this help
EOF
}

has_terminal() {
  [ -r /dev/tty ] && [ -w /dev/tty ] &&
    (: </dev/tty && : >/dev/tty) 2>/dev/null
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

run_mise() {
  "$MISE_BIN" -C "$repo_dir" "$@"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) dry_run=true ;;
    --yes) assume_yes=true ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      fail "unknown option: $1"
      ;;
  esac
  shift
done

[ -x "$MISE_BIN" ] || fail "mise is not installed at $MISE_BIN"
command -v git >/dev/null 2>&1 || fail "git is required"

repo_dir=$(CDPATH= cd -P "$(dirname "$0")" 2>/dev/null && pwd)
[ -f "$repo_dir/mise.toml" ] ||
  fail "run the uninstall script from its dotfiles checkout"

log "Previewing managed dotfile removal"
run_mise bootstrap dotfiles unapply --dry-run

log "Previewing mise removal"
"$MISE_BIN" implode --dry-run

if [ "$dry_run" = true ]; then
  log "Dry run complete; nothing was removed."
  exit 0
fi

if [ "$assume_yes" != true ] && ! confirm_uninstall; then
  log "Uninstall cancelled after the preview."
  exit 0
fi

log "Unapplying managed dotfiles"
run_mise bootstrap dotfiles unapply --yes

log "Removing mise and its installed tools and data"
"$MISE_BIN" implode --yes

# `mise implode` preserves its config directory by default. Remove it only
# when dotfile unapply left it empty; preserve any local configuration files.
rmdir "$HOME/.config/mise" 2>/dev/null || true

log "Uninstall complete. The dotfiles checkout, GitHub authentication data,"
log "Git identity, and /bin/zsh login shell were preserved."
log "Start a fresh login session to discard the current shell environment."
