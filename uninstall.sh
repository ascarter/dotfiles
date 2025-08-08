#!/bin/sh

# Uninstall dotfiles

set -eu

XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
DOTFILES=${DOTFILES:-${XDG_DATA_HOME}/dotfiles}
DOTFILES_CONFIG=${DOTFILES_CONFIG:-${XDG_CONFIG_HOME}/dotfiles}
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

remove_path() {
  path="$1"
  if [ -e "$path" ]; then
    printf "Are you sure you want to remove '%s'? [y/N] " "$path"
    read answer
    case "$answer" in
    [Yy]*)
      echo "Remove $path"
      rm -rf "$path"
      ;;
    *)
      echo "Skip $path"
      ;;
    esac
  else
    echo "Missing $path"
  fi
}

# Remove dotfiles configuration
${DOTFILES}/bin/dotfiles ${FLAGS} -d ${DOTFILES} -t ${TARGET} unlink

remove_path "${DOTFILES_CONFIG}"
remove_path "${DOTFILES}"

echo "dotfiles uninstalled"
echo "Reload session to apply configuration"

# vim: set ft=sh ts=2 sw=2 et:
