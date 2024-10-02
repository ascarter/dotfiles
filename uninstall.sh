#!/bin/sh

# Uninstall dotfiles

set -euo pipefail

DOTFILES=${DOTFILES:-${XDG_CONFIG_HOME:=$HOME/.config}/dotfiles}
TARGET=${TARGET:-$HOME}

usage() {
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  -d  Directory to install dotfiles (default: ${DOTFILES})"
    echo "  -t  Target directory to stow dotfiles (default: ${TARGET})"
    echo "  -h  Show usage"
}

while getopts ":hd:t:" opt; do
  case ${opt} in
    d)  DOTFILES=${OPTARG} ;;
    t)  TARGET=${OPTARG} ;;
    h)  usage && exit 0 ;;
    \?) usage && exit 1 ;;
  esac
done
shift $((OPTIND -1))

echo "Uninstall dotfiles"
${DOTFILES}/bin/dotfiles -t ${TARGET} uninstall

echo "To remove dotfiles, run the following commands:"
echo "rm -rf ${DOTFILES}"
echo ""

echo "----------------------------------------"
echo "dotfiles uninstalled"
echo "Reload session to apply configuration"
echo "----------------------------------------"
