#!/bin/sh

# Install dotfiles

set -eu

: "${XDG_DATA_HOME:=$HOME/.local/share}"
: "${DOTFILES_HOME:=${XDG_DATA_HOME}/dotfiles}"

# Check if git is installed
if ! command -v git >/dev/null 2>&1; then
  echo "Git is not installed."
  exit 1
fi

echo "DOTFILES_HOME: ${DOTFILES_HOME}"

# Clone dotfiles
if [ ! -d "${DOTFILES_HOME}" ]; then
  echo "Clone dotfiles -> ${DOTFILES_HOME}"
  mkdir -p $(dirname "${DOTFILES_HOME}")
  git clone https://github.com/ascarter/dotfiles.git ${DOTFILES_HOME}
fi

# Init dotfiles
if [ -x "${DOTFILES_HOME}/bin/dotfiles" ]; then
  "${DOTFILES_HOME}/bin/dotfiles" init
  "${DOTFILES_HOME}/bin/dotfiles" sync
fi

echo "dotfiles installated"
echo "Reload your session to apply configuration"
