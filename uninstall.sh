#!/bin/sh

# Uninstall dotfiles

set -euo pipefail

DOTFILES=${DOTFILES:-${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles}
TARGET=${TARGET:-$HOME}

usage() {
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  -d  Directory to install dotfiles (default: ${DOTFILES})"
    echo "  -t  Target directory to stow dotfiles (default: ${TARGET})"
    echo "  -v  Verbose output"
    echo "  -h  Show usage"
}

FLAGS=

while getopts ":vhd:t:" opt; do
  case ${opt} in
    d)  DOTFILES=${OPTARG} ;;
    t)  TARGET=${OPTARG} ;;
    v)  FLAGS="-v" ;;
    h)  usage && exit 0 ;;
    \?) usage && exit 1 ;;
  esac
done
shift $((OPTIND -1))

${DOTFILES}/bin/dotfiles ${FLAGS} -d ${DOTFILES} -t ${TARGET} uninstall

echo ""
echo "To remove dotfiles, run the following commands:"
echo "rm -rf ${DOTFILES}"
echo ""

echo "dotfiles uninstalled"
echo "Reload session to apply configuration"
