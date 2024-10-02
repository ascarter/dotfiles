#!/bin/sh

# Install dotfiles

set -euo pipefail

BRANCH=${DOTFILES_BRANCH:-main}
DOTFILES=${DOTFILES:-${XDG_CONFIG_HOME:=$HOME/.config}/dotfiles}
TARGET=${TARGET:-$HOME}

usage() {
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  -b  Branch (default: ${BRANCH})"
    echo "  -d  Directory to install dotfiles (default: ${DOTFILES})"
    echo "  -t  Target directory to stow dotfiles (default: ${TARGET})"
    echo "  -h  Show usage"
}

while getopts ":hb:d:t:" opt; do
  case ${opt} in
    b)  BRANCH=${OPTARG} ;;
    d)  DOTFILES=${OPTARG} ;;
    t)  TARGET=${OPTARG} ;;
    h)  usage && exit 0 ;;
    \?) usage && exit 1 ;;
  esac
done
shift $((OPTIND -1))

# Clone dotfiles
if [ ! -d "${DOTFILES}" ]; then
    echo "Clone dotfiles -> ${DOTFILES}"
    mkdir -p $(dirname "${DOTFILES}")
    git clone -b ${BRANCH} https://github.com/ascarter/dotfiles.git ${DOTFILES}
else
    echo "dotfiles exists"
fi

echo "Init dotfiles"
${DOTFILES}/bin/dotfiles -t ${TARGET} init

echo "Install dotfiles"
${DOTFILES}/bin/dotfiles -t ${TARGET} install

echo "----------------------------------------"
echo "dotfiles installed"
echo "Reload session to apply configuration"
echo "----------------------------------------"
