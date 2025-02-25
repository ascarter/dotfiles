VERBOSE=0

if [ -x "$(command -v mise)" ]; then
  eval "$(mise activate --shims)"
fi

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

# macOS installer functions

macos_prereqs() {
  # Install Xcode Command Line Tools
  if ! [ -e /Library/Developer/CommandLineTools ]; then
    echo "installing" "Xcode Command Line Tools"
    xcode-select --install
    read -p "Press [Enter] to continue..." -n1 -s
    echo
    sudo xcodebuild -runFirstLaunch
  else
    dlog "exists" "Xcode Command Line Tools"
  fi

  # Install homebrew
  if ! [ -d /opt/homebrew ]; then
    # Install Homebrew
    echo "installing" "Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    dlog "exists" "Homebrew"
  fi

  if ! [ -x "$(command -v brew)" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi

  # Enable man page contextual menu item in Terminal.app
  if ! [ -f /usr/local/etc/man.d/homebrew.man.conf ]; then
    dlog "installing" "homrebrew.man.conf"
    sudo mkdir -p /usr/local/etc/man.d
    echo "MANPATH /opt/homebrew/share/man" | sudo tee -a /usr/local/etc/man.d/homebrew.man.conf
  fi

  # Install mise
  if ! [ -x "$(command -v mise)" ]; then
    dlog "installing" "mise"
    brew_install mise
    eval "$(mise activate --shims)"
  fi

  # Configure 1Password CLI
  if ! [ -x "$(command -v op)" ]; then
    dlog "installing" "1Password CLI"
    mise use -g 1password
  fi

  if [ -S ${HOME}/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock ] && ! [ -L ~/.1password/agent.sock ]; then
    dlgo "link" "~/.1password/agent.sock"
    mkdir -p ~/.1password
    ln -s ~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock ~/.1password/agent.sock
  fi

  if [ -L ~/.1password/agent.sock ]; then
    if ! [ -f ~/.ssh/config ] || ! grep -q -x "Include ~/.config/ssh/config" ~/.ssh/config; then
      dlog "enable" "SSH IdentityAgent"
      mkdir -p ~/.ssh
      echo "Include ~/.config/ssh/config" >>~/.ssh/config
    else
      dlog "exists" "SSH IdentityAgent"
    fi
  fi

  # GitHub CLI
  if ! [ -x "$(command -v gh)" ]; then
    dlog "installing" "GitHub CLI"
    mise use -g gh

    # Install GitHub CLI extensions
    gh extension install github/gh-copilot
  fi
}

# Fedora installer functions

fedora_prereqs() {
  echo "Fedora pre-reqs"
}

# Ubuntu installer functions

ubuntu_prereqs() {
  echo "Ubuntu pre-reqs"
}

# GitHub CLI extensions installer

gh_extensions_install() {
  local extensions="github/gh-copilot "

  # Install GitHub CLI extensions
  if [ -x "$(command -v gh)" ]; then
    for extension in $extensions; do
      dlog "installing" "GitHub CLI extension ${extension}"
      gh extension install ${extension}
    done
  fi
}

# 1Password CLI plugins

op_plugins_install() {
  local plugins="gh"

  # Init 1Password CLI plugins
  if [ -x "$(command -v op)" ]; then
    for plugin in $plugins; do
      if [ -x "$(command -v op)" ]; then
        dlog "init" "1Password CLI plugin ${plugin}"
        op plugin init ${plugin}
      fi
    done
  fi
}

prereqs() {
  case "${ID}" in
  "macos") macos_prereqs ;;
  "fedora") fedora_prereqs ;;
  "ubuntu") ubuntu_prereqs ;;
  esac
  op_plugins_install
  gh_extensions_install
}

# Generate zsh completions
update_completions() {
  local completion_dir="${1:-$HOME/.local/share/zsh/functions}"
  local tools
  local tools_cmds

  tools=(
    rustup
    cargo
  )
  tool_cmds=(
    "rustup completions zsh"
    "rustup completions zsh cargo"
  )

  local tool
  local tool_cmd
  local tool_completion

  mkdir -p ${completion_dir}

  for i in "${!tools[@]}"; do
    tool="${tools[$i]}"
    tool_cmd="${tool_cmds[$i]}"
    tool_completion="_${tool}"

    if command -v ${tool} >/dev/null 2>&1; then
      echo "Generating completion for ${tool}..."
      eval "${tool_cmd}" > "${completion_dir}/${tool_completion}"
    else
      echo "Not found ${tool}..."
    fi
  done
}
