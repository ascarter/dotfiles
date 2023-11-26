#!/bin/sh
#
# Install script for my dotfiles
#

set -ueo pipefail

usage() {
  echo "Usage: $0 [-v] [HOMEDIR [DOTFILES]]"
  echo ""
  echo "Install dotfiles to HOMEDIR from DOTFILES."
  echo ""
  echo "HOMEDIR: Home directory (default: \$HOME)"
  echo "DOTFILES: Dotfiles directory (default: \$HOMEDIR/.config/dotfiles)"
  echo "-v: Verbose output"
  echo ""
  echo "Example:"
  echo "  $0"
  echo "  $0 /home/ascarter"
  echo "  $0 /home/ascarter /home/ascarter/.config/dotfiles"
}

install_prerequisites() {
  case $(uname) in
  Darwin )
    echo "Installing on $(sw_vers -productName) $(sw_vers -productVersion)"

    # Verify Xcode installed
    if ! [ -e /usr/bin/xcode-select ]; then
      echo "Xcode required. Install from macOS app store."
      open https://itunes.apple.com/us/app/xcode/id497799835?mt=12
      exit 1
    else
      [ $VERBOSE -eq 1 ] && echo "Xcode installed"
    fi

    # Install Xcode command line tools
    if ! [ -e /Library/Developer/CommandLineTools ]; then
      xcode-select --install
      read -p "Press any key to continue..." -n1 -s
      echo
      sudo xcodebuild -runFirstLaunch
    else
      [ $VERBOSE -eq 1 ] && echo "Xcode command line tools installed"
    fi

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

remove_broken_symlinks() {
  local files=("$@")
  for f in "${files[@]}"; do
    [ $VERBOSE -eq 1 ] && echo "Check symlink ${f}"
    if ! [ -e "${f}" ]; then
      echo "Remove broken symlink ${f}"
      rm "${f}"
    fi
  done
}

# Options
VERBOSE=0

while getopts "hv" opt; do
  case ${opt} in
    h ) usage && exit 0 ;;
    v ) VERBOSE=1 ;;
    \? ) usage && exit 1 ;;
  esac
done
shift $((OPTIND -1))

HOMEDIR="${1:-${HOME}}"
DOTFILES="${2:-${HOMEDIR}/.config/dotfiles}"

echo "Installing dotfiles to ${HOMEDIR} from ${DOTFILES}"

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
  else
    [ $VERBOSE -eq 1 ] && echo "Skip ${t}"
  fi
done

# Check for broken symlinks and clean them up
remove_broken_symlinks $(find ${HOMEDIR} -maxdepth 1 -type l -name '.*' -print)
remove_broken_symlinks $(find ${HOMEDIR}/.config -type l -print)
remove_broken_symlinks $(find ${HOMEDIR}/.local -type l -print)

# Set zsh environment
cat <<EOF > ${HOMEDIR}/.zshenv
export ZDOTDIR=${XDG_CONFIG_HOME:=$HOME/.config}/zsh
export DOTFILES=${DOTFILES}
EOF

echo "dotfiles installed"
echo "Reload session to apply configuration"
