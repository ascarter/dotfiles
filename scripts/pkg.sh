#!/bin/sh

# Run package install

XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
LOCAL_BIN_HOME=${LOCAL_BIN_HOME:-$HOME/.local/bin}
DOTFILES=${DOTFILES:-${XDG_DATA_HOME}/dotfiles}

usage() {
  echo "Install package"
  echo "Usage: pkg [options] (install|uninstall) <package>"
  echo ""
  echo "  install    Install <package>"
  echo "  uninstall  Uninstall <package>"
  echo ""
  echo "Options:"
  echo "  -v  Verbose"
}

# ----------------------------------------
# Main
# ----------------------------------------

VERBOSE=0

while getopts "v" opt; do
  case $opt in
    v)
      VERBOSE=1
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      usage
      exit 1
      ;;
  esac
done

shift $((OPTIND-1))

if [ $# -ne 2 ]; then
  usage
  exit 1
fi

action=$1
package=$2

. ${DOTFILES}/scripts/packages/$package.sh

$action
