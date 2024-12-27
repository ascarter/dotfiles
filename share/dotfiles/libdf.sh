VERBOSE=0

# Emulate os-release
os_release() {
  # Deterine OS and version
  case $(uname -s) in
  Darwin)
    # Configure homebrew shell environment
    if [[ -d /opt/homebrew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    # Emulate /etc/os-release for macOS
    NAME="macOS"
    VERSION=$(sw_vers -productVersion)
    VERSION_ID="$VERSION"
    ID="macos"
    ID_LIKE="darwin"
    BUILD_ID=$(sw_vers -buildVersion)
    PRETTY_NAME="macOS $VERSION ($BUILD_ID)"
    ARCH=$(uname -m)
    OS=$(uname -s)
    ;;
  Linux)
    if [[ -f /etc/os-release ]]; then
      # Source os-release file to get distribution information
      . /etc/os-release
    else
      echo "Error: /etc/os-release not found"
      exit 1
    fi
    ;;
  esac
}
os_release

# Utility installer functions

log() {
  if [ "$#" -eq 1 ]; then
    printf "%s\n" "$1"
  elif [ "$#" -gt 1 ]; then
    printf "$(tput bold)%-10s$(tput sgr0)\t%s\n" "$1" "$2"
  fi
}

# title log
tlog() {
  log "  $1" "$2"
}

# detail log
dlog() {
  tlog "  $1" "$2"
}

vlog() {
  if [ $VERBOSE -eq 1 ]; then
    log "$@"
  fi
}

err() {
  echo "  $(tput bold)error     $(tput sgr0)\t$*" >&2
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

# Homebrew

brew_bundle_install() {
  brewfile=$1
  if brew bundle check --file=$brewfile; then
    dlog "exists" "Brewfile"
  else
    dlog "installing" "Brewfile"
    brew bundle install --file=$brewfile
  fi
}

brew_install() {
  dlog "install" $1
  if brew list -1 | grep -q -w ${1}; then
    brew upgrade ${1}
  else
    brew install ${1}
  fi
}

brew_uninstall() {
  dlog "uninstall" $1
  if brew list -1 | grep -q -w ${1}; then
    brew uninstall ${1}
  else
    err "${1} not installed"
  fi
}

# Fedora/RHEL dnf

dnf_install() {
  if rpm -q ${1}; then
    sudo dnf upgrade ${1}
  else
    sudo dnf install ${1}
  fi
}

dnf_uninstall() {
  if rpm -q ${1}; then
    sudo dnf remove ${1}
  else
    err "${1} not installed"
  fi
}

# Debian/Ubuntu apt

apt_install() {
  if dpkg -l | grep -q -w ${1}; then
    sudo apt-get install --only-upgrade ${1}
  else
    sudo apt-get install ${1}
  fi
}

apt_uninstall() {
  if dpkg -l | grep -q -w ${1}; then
    sudo apt-get purge ${1}
  else
    err "${1} not installed"
  fi
}
