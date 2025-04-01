#!/bin/sh

# Install dotfiles

set -euo pipefail

XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

DOTFILES=${DOTFILES:-${XDG_DATA_HOME}/dotfiles}
DOTFILES_BRANCH=${DOTFILES_BRANCH:-main}
DOTFILES_SCRIPTS=${DOTFILES}/scripts

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

prompt() {
  choice=y
  read -p "$1 (y/N)" -n1 choice
  echo
  case $choice in
  [yY]*) return 0 ;;
  esac
  return 1
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

${DOTFILES}/bin/dotfiles ${FLAGS} -d ${DOTFILES} -t ${TARGET} link

# Prompt to run platform install script
case $(uname -s) in
Darwin)
  if prompt "Run macOS provisioning script?"; then
    ${DOTFILES_SCRIPTS}/macos.sh
  fi
  ;;
Linux)
  if [[ -f /etc/os-release ]]; then
    # Source os-release file to get distribution information
    . /etc/os-release
    case ${ID} in
    fedora)
      if prompt "Run ${ID} ${VARIANT_ID} provisioning script?"; then
        ${DOTFILES_SCRIPTS}/fedora-${VARIANT_ID}
      fi
      ;;
    *)
      if prompt "Run ${ID} provisioning script?"; then
        ${DOTFILES_SCRIPTS}/${ID}.sh
      fi
      ;;
    esac
  else
    echo "/etc/os-release not found"
  fi
  ;;
esac

# Prompt to run developer tools script
if prompt "Run developer tools provisioning script?"; then
  ${DOTFILES_SCRIPTS}/developer.sh
fi

echo ""
echo "dotfiles installed"
echo "Reload session to apply configuration"
