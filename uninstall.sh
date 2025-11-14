#!/bin/sh

# Uninstall dotfiles

set -eu

export XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
export DOTFILES_HOME=${DOTFILES_HOME:-${XDG_DATA_HOME}/dotfiles}

echo "DOTFILES_HOME: ${DOTFILES_HOME}"

prompt() {
  printf "%s (y/N) " "$1" > /dev/tty
  IFS= read -r choice < /dev/tty || choice=""
  case "$choice" in
  [yY]) return 0 ;;
  esac
  return 1
}

if [ -d "${DOTFILES_HOME}" ]; then
  if [ -x "${DOTFILES_HOME}/bin/dotfiles" ] && prompt "Uninstall dotfiles configuration"; then
    "${DOTFILES_HOME}/bin/dotfiles" uninstall
  fi

  if prompt "Delete dotfiles from ${DOTFILES_HOME}"; then
    rm -rf "${DOTFILES_HOME}"
    echo "Dotfiles directory ${DOTFILES_HOME} deleted."
  fi

  echo "Remove dotfiles env from .zshenv if it exists"
  echo "Reload your session"
else
  echo "Dotfiles not installed at ${DOTFILES_HOME}"
fi
