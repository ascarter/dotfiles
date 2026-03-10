# lib/core.sh — shared display, logging, and utility functions
#
# Sourced by bin/dotfiles at startup and by lib/tool.sh for standalone use.
# No shebang — this file is sourced, not executed.
#
# Provides: tty_* variables, log, vlog, warn, error, abort, ensure, success,
#           prompt, platform_id
#
# Globals defaulted (safe to set before sourcing to override):
#   VERBOSE, QUIET, FORCE, FORCE_ALL

# Idempotent guard
[[ -n "${_DOTFILES_CORE_LOADED:-}" ]] && return 0
_DOTFILES_CORE_LOADED=1

# Default control globals if not set by caller
: "${VERBOSE:=0}"
: "${QUIET:=0}"
: "${FORCE:=0}"
: "${FORCE_ALL:=0}"

# ANSI strings
if [[ -t 1 ]]; then
  tty_escape() { printf "\033[%sm" "$1"; }
else
  tty_escape() { :; }
fi
tty_reset="$(tty_escape 0)"
tty_mkbold() { tty_escape "1;$1"; }
tty_underline="$(tty_escape "4;39")"
tty_blue="$(tty_mkbold 34)"
tty_red="$(tty_mkbold 31)"
tty_bold="$(tty_mkbold 39)"

log() {
  case $# in
  0) printf "\n" ;;
  1) printf "%s\n" "$1" ;;
  *)
    label="$1"
    shift
    printf "${tty_bold}%s${tty_reset} " "${label}"
    message="$1"
    shift
    printf "%s\n" "$message"

    if [ "$VERBOSE" -eq 1 ]; then
      for arg; do
        [ -n "$arg" ] || continue
        printf "\t\t%s\n" "$arg"
      done
    fi
    ;;
  esac
}

vlog() {
  if [ "$VERBOSE" -eq 1 ]; then
    log "$@"
  fi
}

error() {
  printf "${tty_red}error${tty_reset} %s\n" "$*" >&2
}

warn() {
  label="${1:-warning}"
  shift
  printf "${tty_blue}%s${tty_reset} %s\n" "$label" "$*" >&2
}

abort() {
  error "$@"
  exit 1
}

ensure() {
  if ! "$@"; then
    abort "command failed: $*"
  fi
}

success() {
  log "$@"
  log "Restart your shell or run \`source ~/.zshenv\`"
  exit 0
}

prompt() {
  if [ "$FORCE_ALL" -eq 1 ]; then
    return 0
  fi

  printf "%s (y/N/a) " "$1" >/dev/tty
  IFS= read -r choice </dev/tty || choice=""
  case "$choice" in
  [yY]) return 0 ;;
  [a])
    FORCE_ALL=1
    return 0
    ;;
  esac
  return 1
}

platform_id() {
  case "$(uname -s)" in
  Darwin)
    echo "macos"
    ;;
  Linux)
    if [ -f /etc/os-release ]; then
      . /etc/os-release
      echo "${ID}"
    else
      echo "linux-unknown"
    fi
    ;;
  *)
    echo "unknown"
    ;;
  esac
}
