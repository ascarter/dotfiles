#!/bin/sh

# Install dotfiles tool

set -euo pipefail

usage() {
    echo "Usage: $0 [-v] [-h] [-b branch] [-f] [DOTFILES]"
    echo
    echo "Options:"
    echo "  -v: Verbose output"
    echo "  -h: Show usage"
    echo "  -b: Branch"
    echo "  -f: Force"
    echo
    echo "DOTFILES: Directory to install dotfiles"
    echo
}

# Options:
# -v: Verbose output
# -h: Show usage
# -b: Branch
# -f: Force
BRANCH=main
FORCE=0
while getopts "vhb:f" opt; do
  case ${opt} in
    v)  set -x ;;
    b)  BRANCH=${OPTARG} ;;
    f)  FORCE=1 ;;
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
    echo "Dotfiles already exists"
fi

# Install link to dotfiles if not exists
if [ ! -x "${HOME}/.local/bin/dotfiles" ]; then
    mkdir -p ${HOME}/.local/bin
    ln -sf ${DOTFILES}/bin/dotfiles ${HOME}/.local/bin/dotfiles
    echo "dotfiles tool installed"
else
    echo "dotfiles tool already exists"
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
