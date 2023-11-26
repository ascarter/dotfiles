#!/bin/sh
#
# Uninstall script for my dotfiles

set -ueo pipefail

usage() {
  echo "Usage: $0 [-nv]"
  echo ""
  echo "Uninstall dotfiles"
  echo ""
  echo "-n: Do not not prompt for confirmation"
  echo "-v: Verbose output"
}

log() {
  echo "${DRYRUN:+\033[0;33m[DRYRUN]\033[0m }$1"
}

safe_rm() {
  if [ $DRYRUN -eq 0 ]; then
    rm "$1"
  fi
}

safe_mv() {
  if [ $DRYRUN -eq 0 ]; then
    mv "$1" "$2"
  fi
}

remove_symlinks() {
  for f in $(find ${SRCDIR} -type f -print); do
    t=${HOMEDIR}/.${f#${SRCDIR}/}
    if [ -h "${t}" ]; then
      log "Removing symlink ${t}"
      safe_rm "${t}"
      if [ -f "${t}.orig" ]; then
        log "Restoring backup ${t}.orig -> ${t}"
        safe_mv "${t}.orig" "${t}"
      fi
    fi
  done
}

remove_zshenv() {
  log "Removing ~/.zshenv"
  safe_rm "${HOMEDIR}/.zshenv"
}

remove_homebrew() {
  log "Uninstalling Homebrew"
  if [ $DRYRUN -eq 0 ]; then
    /bin/bash -c "$(curl -fsSL ${HOMEBREW_UNINSTALL_URL})"
  fi
}

prompt() {
  choice=y
  if [ $NON_INTERACTIVE -eq 0 ]; then
    read -p "$1 (y/N)" -n1 choice
    echo
  fi
  case $choice in
  [yY]*) return 0 ;;
  esac

  return 1
}

# Options
DRYRUN=0
NON_INTERACTIVE=0
VERBOSE=0

while getopts "dhnv" opt; do
  case ${opt} in
    d ) DRYRUN=1 ;;
    h ) usage && exit 0 ;;
    n ) NON_INTERACTIVE=1 ;;
    v ) VERBOSE=1 ;;
    \? ) usage && exit 1 ;;
  esac
done
shift $((OPTIND -1))

HOMEDIR="${1:-${HOME}}"
DOTFILES="${DOTFILES:-${2:-${HOMEDIR}/.config/dotfiles}}"
SRCDIR="${DOTFILES}/home"
HOMEBREW_UNINSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh"

echo "Uninstalling dotfiles"
echo "----------------------------------------"
echo "  DOTFILES: ${DOTFILES}"
echo "  HOME:     ${HOMEDIR}"
echo "----------------------------------------"

if prompt "Remove symlinks and restore backups?" ; then
  remove_symlinks
fi

if [ -f "${HOMEDIR}/.zshenv" ] && prompt "Remove zshenv?" ; then
  remove_zshenv
fi

if [ -d /opt/homebrew ] && prompt "Uninstall Homebrew?" ; then
  remove_homebrew
fi

echo "----------------------------------------"
echo "dotfiles uninstalled"
echo "Reload session to apply configuration"
echo "----------------------------------------"
