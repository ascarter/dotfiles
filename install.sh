#!/bin/sh
#
# Install script for my dotfiles
#
# Usage:
#   install.sh [HOMEDIR [DOTFILES]]
#
#   HOMEDIR: Home directory (default: $HOME)
#   DOTFILES: Dotfiles directory (default: $HOMEDIR/.config/dotfiles)
#
# Example:
#   install.sh
#   install.sh /home/ascarter
#   install.sh /home/ascarter /home/ascarter/.config/dotfiles

set -ueo pipefail

install_prerequisites() {
  case $(uname) in
  Darwin )
    # Install Homebrew
    if ! command -v brew >/dev/null 2>&1; then
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    # Install packages
    # brew bundle --file="$PWD/home/Brewfile"
    ;;
  Linux )
    # TODO
    ;;
  esac
}

HOMEDIR="${HOMEDIR:-${1:-${HOME}}}"
DOTFILES="${DOTFILES:-${2:-${HOMEDIR}/.config/dotfiles}}"

install_prerequisites

# Clone dotfiles
if [ ! -d "${DOTFILES}" ]; then
  mkdir -p $(dirname "${DOTFILES}")
  git clone https://github.com/ascarter/dotfiles ${DOTFILES}
fi

# Symlink dotfiles
SRCDIR="${DOTFILES}/home"
mkdir -p ${HOMEDIR}
for f in $(find ${SRCDIR} -type f -print); do
  t=${HOMEDIR}/.${f#${SRCDIR}/}
  if ! [ -h "${t}" ]; then
    # Preserve original file
    if [ -e "${t}" ]; then
      echo "Backup ${t} -> ${t}.orig"
      mv "${t}" "${t}.orig"
    fi

    # Symlink file
    echo "Symlink ${f} -> ${t}"
    mkdir -p $(dirname "${t}")
    ln -s ${f} ${t}
  fi
done
