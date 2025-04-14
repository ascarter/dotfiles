#!/bin/sh

# Uninstall dotfiles

set -eu

XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
LOCAL_BIN_HOME=${LOCAL_BIN_HOME:-$HOME/.local/bin}
DOTFILES=${DOTFILES:-${XDG_DATA_HOME}/dotfiles}
TARGET=${TARGET:-$HOME}

usage() {
  echo "Usage: $0 [options]"
  echo
  echo "Options:"
  echo "  -d  Dotfiles directory (default: ${DOTFILES})"
  echo "  -t  Target directory to remove symlinks to dotfiles (default: ${TARGET})"
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

# Remove symlinks
for dfbin in ${DOTFILES}/bin/* ; do
  bin="$LOCAL_BIN_HOME/${dfbin##*/}"
  if [ -L $bin ]; then
    echo "Remove $bin"
    rm $bin
  fi
done

# Remove dotfiles
if [ -d "${DOTFILES}" ]; then
  choice=N
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

# vim: set ft=sh ts=2 sw=2 et:
