#!/bin/sh
#
# Test script for my dotfiles
#

set -xueo pipefail

usage() {
  echo "Usage: $0 [-c] [-i] [-o] [-u] [HOMEDIR [DOTFILES]]"
  echo "  -c: Cleanup"
  echo "  -i: Test install.sh"
  echo "  -o: Create dummy files in HOMEDIR"
  echo "  -u: Test uninstall.sh"
  echo "  If no options specified, all tests will be run."
  echo "  HOMEDIR: Home directory (default: \$HOME)"
  echo "  DOTFILES: Dotfiles directory (default: \$HOMEDIR/.config/dotfiles)"
  echo "  If HOMEDIR not specified, a temp directory will be created."
}

CLEANUPMODE=0
INSTALLMODE=0
ORIGMODE=0
UNINSTALLMODE=0

while getopts "ciou" opt; do
  case ${opt} in
    c ) CLEANUPMODE=1 ;;
    i ) INSTALLMODE=1 ;;
    o ) ORIGMODE=1 ;;
    u ) UNINSTALLMODE=1 ;;
    \? ) usage && exit 1 ;;
  esac
done
shift $((OPTIND -1))

# If no options set, turn them all on as default
if [ "${CLEANUPMODE:-0}${INSTALLMODE:-0}${ORIGMODE:-0}${UNINSTALLMODE:-0}" = "0000" ]; then
  CLEANUPMODE=1
  INSTALLMODE=1
  ORIGMODE=1
  UNINSTALLMODE=1
fi

# Make a temp test directory if needed
HOMEDIR="${1:-$(mktemp -d dftest.XXXXXX)}"
DOTFILES="${2:-$PWD}"
echo "Test mode: ${HOMEDIR} ${DOTFILES}"

# If no options specified, show usage and exit
if [ "${CLEANUPMODE:-0}${INSTALLMODE:-0}${ORIGMODE:-0}${UNINSTALLMODE:-0}" = "0000" ]; then
  usage
  exit 1
fi

# Run install test
if [ "${INSTALLMODE:-0}" = "1" ]; then
  # Create dummy files
  if [ "${ORIGMODE:-0}" = "1" ]; then
    SRCDIR="${DOTFILES}/home"
    for f in $(find ${SRCDIR} -type f -print); do
      t=${HOMEDIR}/.${f#${SRCDIR}/}
      mkdir -p $(dirname "${t}")
      touch ${t}
    done
  fi

  # Run install script
  ${DOTFILES}/install.sh ${HOMEDIR} ${DOTFILES}
fi

# Run uninstall test
if [ "${UNINSTALLMODE:-0}" = "1" ]; then
  ${DOTFILES}/uninstall.sh ${HOMEDIR} ${DOTFILES}
fi

# Cleanup
if [ "${CLEANUPMODE:-0}" = "1" ]; then
  # Confirm user wants to delete test directory
  read -p "Delete ${HOMEDIR}? [y/N] " -n 1 -r
  echo

  if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf ${HOMEDIR}
  fi
fi
