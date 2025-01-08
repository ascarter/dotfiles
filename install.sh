#!/bin/sh

# Install dotfiles

set -euo pipefail

XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
DOTFILES=${DOTFILES:-${XDG_CONFIG_HOME}/dotfiles}
DOTFILES_BRANCH=${DOTFILES_BRANCH:-main}
TARGET=${TARGET:-$HOME}

usage() {
  echo "Usage: $0 [options]"
  echo
  echo "Options:"
  echo "  -b  Branch (default: ${DOTFILES_BRANCH})"
  echo "  -d  Directory to install dotfiles (default: ${DOTFILES})"
  echo "  -t  Target directory to stow dotfiles (default: ${TARGET})"
  echo "  -v  Verbose output"
  echo "  -h  Show usage"
}

FLAGS=

while getopts ":vhb:d:t:" opt; do
  case ${opt} in
  b) DOTFILES_BRANCH=${OPTARG} ;;
  d) DOTFILES=${OPTARG} ;;
  t) TARGET=${OPTARG} ;;
  v) FLAGS="-v" ;;
  h) usage && exit 0 ;;
  \?) usage && exit 1 ;;
  esac
done
shift $((OPTIND - 1))

# Clone dotfiles
if [ ! -d "${DOTFILES}" ]; then
  echo "Clone dotfiles ($DOTFILES_BRANCH) -> ${DOTFILES}"
  mkdir -p $(dirname "${DOTFILES}")
  git clone -b ${DOTFILES_BRANCH} https://github.com/ascarter/dotfiles.git ${DOTFILES}
else
  echo "dotfiles exists"
fi

${DOTFILES}/bin/dotfiles ${FLAGS} -d ${DOTFILES} -t ${TARGET} init

echo ""
echo "dotfiles installed"
echo "Reload session to apply configuration"
