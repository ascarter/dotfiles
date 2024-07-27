#!/bin/sh

set -euo pipefail

XDG_CONFIG_HOME=${XDG_CONFIG_HOME:=$HOME/.config}
DOTFILES=${DOTFILES:=$XDG_CONFIG_HOME/dotfiles}
DOTFILES_LIB=${DOTFILES_LIB:=$DOTFILES/lib}

VERBOSE=0
FORCE=0

# Utility installer functions

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

# macOS installer functions

macos_prereqs() {
    # Install Xcode Command Line Tools
    if ! [ -e /Library/Developer/CommandLineTools ]; then
        echo "Installing Xcode Command Line Tools"
        xcode-select --install
        read -p "Press [Enter] to continue..." -n1 -s
        echo
        sudo xcodebuild -runFirstLaunch
    else
        log "Xcode Command Line Tools installed"
    fi

    # Install Rosetta 2
    # if [ "$(uname -m)" = "arm64" ]; then
    #     if ! arch -x86_64 /usr/bin/true 2> /dev/null; then
    #         echo "Installing Rosetta 2"
    #         softwareupdate --install-rosetta --agree-to-license
    #     else
    #         log "Rosetta 2 installed"
    #     fi
    # fi

    if ! [ -x "$(command -v brew)" ]; then
        # Install Homebrew
        echo "Installing Homebrew"
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
}

brew_bundle_install() {
    local brewfile=$1
    if brew bundle check --file=$brewfile; then
        log "Brewfile already installed"
    else
        brew bundle install --file=$brewfile
    fi
}

brew_install() {
    log "Installing $1 with Homebrew"
    if brew list -1 | grep -q -w ${1}; then
        brew upgrade ${1}
    else
        brew install ${1}
    fi
}

# Fedora installer functions

dnf_install() {
    if rpm -q ${1}; then
        sudo dnf upgrade ${1}
    else
        sudo dnf install ${1}
    fi
}

fedora_prereqs() {
    echo "Fedora pre-reqs"
}

# Ubuntu installer functions

apt_install() {
    if dpkg -l | grep -q -w ${1}; then
        sudo apt-get install --only-upgrade ${1}
    else
        sudo apt-get install ${1}
    fi
}

ubuntu_prereqs() {
    echo "Ubuntu pre-reqs"    
}

case $(uname -s) in
Darwin )
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
    ;;
Linux )
    if [[ -f /etc/os-release ]]; then
        # Source os-release file to get distribution information
        . /etc/os-release
    else
        echo "Error: /etc/os-release not found"
        exit 1
    fi
    ;;
esac
