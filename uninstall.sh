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

# mise uninstall
if [ -x "$(command -v mise)" ]; then
  read -p "Uninstall mise? (y/N) " confirm
  if [ "${confirm:-N}" = "y" ]; then
    mise implode
  fi
fi

# brew uninstall
if [ -x "$(command -v brew)" ]; then
  read -p "Uninstall Homebrew? (y/N) " confirm
  if [ "${confirm:-N}" = "y" ]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
  fi
fi

# Remove dotfiles
if [ -d "${DOTFILES}" ]; then
  read -p "Uninstall dotfiles -> ${DOTFILES}? (y/N) " confirm
  if [ "${confirm:-N}" = "y" ]; then
    ${DOTFILES}/bin/dotfiles ${FLAGS} -d ${DOTFILES} -t ${TARGET} unlink
  fi

  read -p "Remove dotfiles directory -> ${DOTFILES}? (y/N) " confirm
  if [ "${confirm:-N}" = "y" ]; then
    rm -rf ${DOTFILES}
  fi

  echo "dotfiles uninstalled"
  echo "Reload session to apply configuration"
else
  echo "dotfiles not found"
  exit 1
fi
