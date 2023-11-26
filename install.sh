#!/bin/sh
#
# Install script for my dotfiles
#

set -ueo pipefail

usage() {
  echo "Usage: $0 [-nv] [HOMEDIR [DOTFILES]]"
  echo ""
  echo "Install dotfiles to HOMEDIR from DOTFILES."
  echo ""
  echo "HOMEDIR: Home directory (default: \$HOME)"
  echo "DOTFILES: Dotfiles directory (default: \$HOMEDIR/.config/dotfiles)"
  echo "-n: Do not install homebrew"
  echo "-v: Verbose output"
  echo ""
  echo "Example:"
  echo "  $0"
  echo "  $0 /home/ascarter"
  echo "  $0 /home/ascarter /home/ascarter/.config/dotfiles"
}

log() {
  if [ $VERBOSE -eq 1 ]; then
    echo $1
  fi
}

install_prerequisites() {
  case $(uname) in
  Darwin )
    echo "$(sw_vers -productName) $(sw_vers -productVersion)"

    # Install Xcode
    if ! [ -e /usr/bin/xcode-select ]; then
      echo "Xcode required. Install from macOS app store."
      open https://itunes.apple.com/us/app/xcode/id497799835?mt=12
      exit 1
    else
      echo "Xcode installed"
    fi

    # Install Xcode command line tools
    if ! [ -e /Library/Developer/CommandLineTools ]; then
      xcode-select --install
      read -p "Press any key to continue..." -n1 -s
      echo
      sudo xcodebuild -runFirstLaunch
    else
      echo "Xcode command line tools installed"
    fi

    # Install Rosetta 2
    softwareupdate --install-rosetta
    ;;
  Linux )
    # TODO
    ;;
  esac
}

install_homebrew() {
  case $(uname) in
  Darwin )
    # Install Homebrew
    if ! command -v brew >/dev/null 2>&1; then
      echo "Installing homebrew"
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
      echo "Homebrew installed"
    fi

    # Install packages
    if command -v brew >/dev/null 2>&1; then
      brew bundle --file="$PWD/home/Brewfile"
    fi
    ;;
  Linux )
    # TODO
    ;;
  esac
}

remove_broken_symlinks() {
  local files=("$@")
  for f in "${files[@]}"; do
    log "Check symlink ${f}"
    if ! [ -e "${f}" ]; then
      echo "Remove broken symlink ${f}"
      rm "${f}"
    fi
  done
}

# Options
VERBOSE=0
SKIP_HOMEBREW=0

while getopts "hnv" opt; do
  case ${opt} in
    h ) usage && exit 0 ;;
    n ) SKIP_HOMEBREW=1 ;;
    v ) VERBOSE=1 ;;
    \? ) usage && exit 1 ;;
  esac
done
shift $((OPTIND -1))

HOMEDIR="${1:-${HOME}}"
DOTFILES="${2:-${HOMEDIR}/.config/dotfiles}"

echo "Installing dotfiles"
echo "----------------------------------------"
echo "  DOTFILES: ${DOTFILES}"
echo "  HOME:     ${HOMEDIR}"
echo "----------------------------------------"

install_prerequisites

if [ $SKIP_HOMEBREW -eq 0 ]; then
  install_homebrew
fi

# Clone dotfiles
echo "Installing dotfiles ${DOTFILES} -> ${HOMEDIR}"
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
    log "Skip ${t}"
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

echo "----------------------------------------"
echo "dotfiles installed"
echo "Reload session to apply configuration"
echo "----------------------------------------"
