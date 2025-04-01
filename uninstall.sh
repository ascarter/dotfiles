#!/bin/sh

# Uninstall dotfiles

set -euo pipefail

XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
DOTFILES=${DOTFILES:-${XDG_DATA_HOME}/dotfiles}
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
  d) DOTFILES=${OPTARG} ;;
  t) TARGET=${OPTARG} ;;
  v) FLAGS="-v" ;;
  h) usage && exit 0 ;;
  \?) usage && exit 1 ;;
  esac
done
shift $((OPTIND - 1))

${DOTFILES}/bin/dotfiles ${FLAGS} -d ${DOTFILES} -t ${TARGET} unlink

# Remove dotfiles
if [ -d "${DOTFILES}" ]; then
  choice=y
  read -p "Remove dotfiles directory -> ${DOTFILES}? (y/N)" -n1 choice
  echo
  case $choice in
  [yY]*) rm -rf ${DOTFILES} ;;
  esac
  echo "dotfiles uninstalled"
  echo "Reload session to apply configuration"
else
  echo "dotfiles not found"
  exit 1
fi
