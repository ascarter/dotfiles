#!/bin/sh

# Install dotfiles

set -eu

# Define XDG directories if not already set
XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
LOCAL_BIN_HOME=${LOCAL_BIN_HOME:-$HOME/.local/bin}

# Default directories and settings
DOTFILES=${DOTFILES:-${XDG_DATA_HOME}/dotfiles}
DOTFILES_BRANCH=${DOTFILES_BRANCH:-main}
DOTFILES_LIB=${DOTFILES}/lib
TARGET=${TARGET:-$HOME}

usage() {
  echo "Usage: $0 [options]"
  echo
  echo "Options:"
  echo "  -b  Branch (default: ${DOTFILES_BRANCH})"
  echo "  -d  Directory to install dotfiles (default: ${DOTFILES})"
  echo "  -t  Target directory to create symlinks to dotfiles (default: ${TARGET})"
  echo "  -v  Verbose output"
  echo "  -h  Show usage"
}

prompt() {
  choice="N"
  read -p "$1 (y/N) " -n 1 choice
  echo
  case $choice in
    [yY]) return 0 ;;
    *) return 1 ;;
  esac
}

get_platform_id() {
  case "$(uname -s)" in
    Darwin)
      echo "macos"
      ;;
    Linux)
      if [ -f /etc/os-release ]; then
        # Source the os-release file to get ID and VARIANT_ID
        . /etc/os-release
        if [ -n "${VARIANT_ID:-}" ]; then
          echo "${ID}-${VARIANT_ID}"
        else
          echo "${ID}"
        fi
      else
        echo "linux-unknown"
      fi
      ;;
    *)
      echo "unknown"
      ;;
  esac
}

FLAGS=""

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
  echo "dotfiles directory already exists at ${DOTFILES}"
  if prompt "Update existing dotfiles?"; then
    echo "Updating dotfiles..."
    git -C "${DOTFILES}" pull
  fi
fi

# Install dotfiles symlinks
for dfbin in ${DOTFILES}/bin/* ; do
  bin="$LOCAL_BIN_HOME/${dfbin##*/}"
  if ! [ -L $bin ]; then
    if [ -e $bin ]; then
      echo "Conflict: $bin exists" >&2
    else
      echo "link $dfbin -> $bin"
      ln -s $dfbin $bin
    fi
  fi
done

# Init dotfiles
"${DOTFILES}/bin/dotfiles" ${FLAGS} -d "${DOTFILES}" -t "${TARGET}" init

# Link dotfiles
"${DOTFILES}/bin/dotfiles" ${FLAGS} -d "${DOTFILES}" -t "${TARGET}" link

# Identify platform and run appropriate installation script
PLATFORM_ID=$(get_platform_id)
PLATFORM_SCRIPT="${DOTFILES_LIB}/os/${PLATFORM_ID}.sh"

if [ -f "${PLATFORM_SCRIPT}" ]; then
  if prompt "Run ${PLATFORM_ID} provisioning script?"; then
    "${PLATFORM_SCRIPT}"
  fi
else
  echo "No provisiong script found for ${PLATFORM_ID}"
fi

echo ""
echo "dotfiles installation complete"
echo "Reload your session to apply configuration"

# vim: set ft=sh ts=2 sw=2 et:
