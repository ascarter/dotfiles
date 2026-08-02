#!/bin/sh

set -eu

readonly DEFAULT_REPO_URL="https://github.com/ascarter/dotfiles.git"
readonly DEFAULT_REPO_DIR="${HOME}/Developer/dotfiles"
readonly MISE_BIN="${HOME}/.local/bin/mise"
readonly MISE_CONFIG_RELATIVE=".mise/config.toml"

dry_run=false
assume_yes=false

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

usage() {
  cat <<'EOF'
Usage: bootstrap.sh [--dry-run] [--yes]

Install mise at ~/.local/bin/mise, obtain the dotfiles repository when this
script is piped into sh, and bootstrap dotfiles, zsh, gh, and GitHub access.

Options:
  --dry-run  Preview mise's bootstrap without applying it
  --yes      Skip this script's confirmation prompt
  -h, --help Show this help

Environment:
  DOTFILES_REPO_DIR  Checkout location (default: ~/Developer/dotfiles)
  DOTFILES_REPO_URL  Public Git clone URL
EOF
}

has_terminal() {
  [ -r /dev/tty ] && [ -w /dev/tty ] &&
    (: </dev/tty && : >/dev/tty) 2>/dev/null
}

confirm_apply() {
  if ! has_terminal; then
    fail "confirmation needs a terminal; rerun with --dry-run or --yes"
  fi

  printf 'Apply this bootstrap? [y/N] ' >/dev/tty
  IFS= read -r answer </dev/tty || answer=
  case "$answer" in
    y | Y | yes | YES | Yes) return 0 ;;
    *) return 1 ;;
  esac
}

script_checkout() {
  case "$0" in
    */bootstrap.sh | bootstrap.sh)
      candidate=$(CDPATH= cd -P "$(dirname "$0")" 2>/dev/null && pwd)
      if [ -f "$candidate/$MISE_CONFIG_RELATIVE" ]; then
        printf '%s\n' "$candidate"
        return 0
      fi
      ;;
  esac
  return 1
}

ensure_checkout() {
  if [ -f "$repo_dir/$MISE_CONFIG_RELATIVE" ]; then
    return 0
  fi

  if [ -e "$repo_dir" ] && [ ! -d "$repo_dir" ]; then
    fail "$repo_dir exists but is not a directory"
  fi

  if [ -d "$repo_dir" ] && [ -n "$(find "$repo_dir" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]; then
    fail "$repo_dir exists but is not a dotfiles checkout"
  fi

  log "Cloning dotfiles into $repo_dir"
  mkdir -p "$(dirname "$repo_dir")"
  git clone "$repo_url" "$repo_dir"
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

run_mise() {
  MISE_GLOBAL_CONFIG_FILE="$repo_dir/src/config/mise/config.toml" \
    MISE_GLOBAL_CONFIG_ROOT="$HOME" \
    "$MISE_BIN" -C "$repo_dir" "$@"
}

run_bootstrap() {
  run_mise bootstrap --only dotfiles,user,tools,task "$@"
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

require_commands curl git /bin/zsh

repo_url=${DOTFILES_REPO_URL:-$DEFAULT_REPO_URL}
if [ -n "${DOTFILES_REPO_DIR:-}" ]; then
  repo_dir=$DOTFILES_REPO_DIR
elif checkout=$(script_checkout); then
  repo_dir=$checkout
else
  repo_dir=$DEFAULT_REPO_DIR
fi

ensure_checkout
install_mise

"$MISE_BIN" trust "$repo_dir/$MISE_CONFIG_RELATIVE"

log "Previewing the dotfiles, login shell, tools, and final user setup"
run_bootstrap --dry-run

if [ "$dry_run" = true ]; then
  log "Dry run complete; nothing from mise bootstrap was applied."
  exit 0
fi

if [ "$assume_yes" != true ] && ! confirm_apply; then
  log "Bootstrap cancelled after the preview."
  exit 0
fi

log "Applying bootstrap"
run_bootstrap --yes

log "Bootstrap complete. Start a new login shell with: exec /bin/zsh -l"
