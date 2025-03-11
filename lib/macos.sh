# macOS
brew_install() {
  if ! [ -d /opt/homebrew ]; then
    # Install Homebrew
    echo "installing" "Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    dlog "exists" "brew"
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
}

brew_update() {
  if [ -x "$(command -v brew)" ]; then
    dlog "update" "brew"

    if ! brew bundle check --global; then
      dlog "installing" "brewfile"
      brew bundle install --global
    fi

    dlog "upgrading" "brew"
    brew upgrade
  fi
}

xcode_install() {
  if ! [ -e /Library/Developer/CommandLineTools ]; then
    dlog "install" "xcode"
    xcode-select --install
    read -p "Press [Enter] to continue..." -n1 -s
    echo
    sudo xcodebuild -runFirstLaunch
  else
    dlog "exists" "xcode"
  fi
}

macos_reqs() {
  xcode_install
  brew_install
  brew_update
}
