#!/bin/sh

# Install dotfiles tool

set -euo pipefail

usage() {
    echo "Usage: $0 [-v] [-h] [-b branch] [DOTFILES]"
    echo
    echo "Options:"
    echo "  -b: Branch"
    echo "  -h: Show usage"
    echo
    echo "DOTFILES: Directory to install dotfiles"
    echo
}

BRANCH=${DOTFILES_BRANCH:-main}

while getopts "hb:" opt; do
  case ${opt} in
    b)  BRANCH=${OPTARG} ;;
    h)  usage && exit 0 ;;
    \?) usage && exit 1 ;;
  esac
done
shift $((OPTIND -1))

DOTFILES="${1:-${XDG_CONFIG_HOME:=$HOME/.config}/dotfiles}"

# Clone dotfiles
if [ ! -d "${DOTFILES}" ]; then
    echo "Clone dotfiles -> ${DOTFILES}"
    mkdir -p $(dirname "${DOTFILES}")
    git clone -b ${BRANCH} https://github.com/ascarter/dotfiles.git ${DOTFILES}
else
    echo "dotfiles exists"
fi

# Install link to dotfiles if not exists
if [ ! -x "${HOME}/.local/bin/dotfiles" ]; then
    mkdir -p ${HOME}/.local/bin
    ln -sf ${DOTFILES}/bin/dotfiles ${HOME}/.local/bin/dotfiles
    echo "dotfiles tool installed"
else
    echo "dotfiles tool exists"
fi

echo
echo "To install dotfiles, run:"
echo "  dotfiles install"
echo
echo "To update dotfiles, run:"
echo "  dotfiles update"
echo
echo "To uninstall dotfiles, run:"
echo "  dotfiles uninstall"
echo
echo "To see all available commands, run:"
echo "  dotfiles help"
echo
