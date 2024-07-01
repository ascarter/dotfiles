#!/bin/sh
#
# Install script for my dotfiles
#

set -euo pipefail

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
    if [ "$#" -eq 1 ]; then
      printf "%s\n" "$1"
    elif [ "$#" -gt 1 ]; then
      printf "$(tput bold)%-10s$(tput sgr0)\t%s\n" "$1" "$2"
    fi
  fi
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

osinfo() {
  case $(uname) in
  Darwin) echo "$(sw_vers -productName) $(sw_vers -productVersion)" ;;
  esac
}

install_prerequisites() {
  case $(uname) in
  Darwin )
    # Install Xcode
    if ! [ -e /usr/bin/xcode-select ]; then
      echo "Xcode required. Install from macOS app store."
      open https://itunes.apple.com/us/app/xcode/id497799835?mt=12
      exit 1
    else
      log "Xcode installed"
    fi

    # Install Xcode command line tools
    if ! [ -e /Library/Developer/CommandLineTools ]; then
      xcode-select --install
      read -p "Press any key to continue..." -n1 -s
      echo
      sudo xcodebuild -runFirstLaunch
    else
      log "Xcode command line tools installed"
    fi

    # Install Rosetta 2
    if ! pgrep -q oahd ; then
      softwareupdate --install-rosetta
    else
      log "Rosetta 2 installed"
    fi
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
      eval "$(/opt/homebrew/bin/brew shellenv)"
    else
      log "Homebrew installed"
    fi

    # Enable man page contextual menu item in Terminal.app
    if ! [ -f /usr/local/etc/man.d/homebrew.man.conf ]; then
      sudo mkdir -p /usr/local/etc/man.d
      echo "MANPATH /opt/homebrew/share/man" | sudo tee -a /usr/local/etc/man.d/homebrew.man.conf
    fi

    # Install packages
    if command -v brew >/dev/null 2>&1; then
      for f in ${DOTFILES}/homebrew/* ; do
        if prompt "Install Homebrew packages from $(basename ${f})?" ; then
          brew bundle --no-lock --file="${f}" || true
        fi
      done
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
DOTFILES="${2:-${XDG_CONFIG_HOME:=$HOME/.config}/dotfiles}"
STATUS="updated"
SEPARATOR="--------------------------------------------------"

log ${SEPARATOR}
log "DOTFILES" ${DOTFILES}
log "HOME" ${HOMEDIR}
log "OS" "$(osinfo)"
log ${SEPARATOR}

install_prerequisites

if [ $SKIP_HOMEBREW -eq 0 ]; then
  install_homebrew
fi

# Clone dotfiles
if [ ! -d "${DOTFILES}" ]; then
  STATUS="installed"
  echo "Clone dotfiles -> ${DOTFILES}"
  mkdir -p $(dirname "${DOTFILES}")
  git clone https://github.com/ascarter/dotfiles ${DOTFILES}
fi

# Symlink dotfiles
SRCDIR="${DOTFILES}/conf"
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
    echo "Link ${f} -> ${t}"
    mkdir -p $(dirname "${t}")
    ln -s ${f} ${t}
  else
    log "Skip ${t}"
  fi
done

# Check for broken symlinks and clean them up
#remove_broken_symlinks $(find ${HOMEDIR} -maxdepth 1 -type l -name '.*' -print)
#remove_broken_symlinks $(find ${HOMEDIR}/.config -type l -print)
#remove_broken_symlinks $(find ${HOMEDIR}/.local -type l -print | grep -v "${HOMEDIR}/.local/share/Steam")

# Set zsh environment
cat <<EOF > ${HOMEDIR}/.zshenv
export ZDOTDIR=${XDG_CONFIG_HOME:=$HOME/.config}/zsh
if [[ -f \${ZDOTDIR}/.zshenv ]]; then
  source \${ZDOTDIR}/.zshenv
fi
EOF

echo ${SEPARATOR}
echo "dotfiles" ${STATUS}
echo "Reload session to apply configuration"
echo ${SEPARATOR}
