# Homebrew

export HOMEBREW_BUNDLE_FILE_GLOBAL=${HOMEBREW_BUNDLE_FILE_GLOBAL:-${XDG_CONFIG_HOME}/homebrew/Brewfile}

brew_env() {
  if [ -d /opt/homebrew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -d /home/linuxbrew/.linuxbrew ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  fi
}

brew_install() {
  brew_env

  if ! [ -x "$(command -v brew)" ]; then
    # Install Homebrew
    echo "installing" "Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    dlog "exists" "brew"
  fi

  # Enable man page contextual menu item in Terminal.app
  if ! [ -f /usr/local/etc/man.d/homebrew.man.conf ]; then
    dlog "installing" "homrebrew.man.conf"
    sudo mkdir -p /usr/local/etc/man.d
    echo "MANPATH /opt/homebrew/share/man" | sudo tee -a /usr/local/etc/man.d/homebrew.man.conf
  fi
}

brew_update() {
  brew_env

  if [ -x "$(command -v brew)" ]; then
    dlog "update" "brew"

    if ! brew bundle check --global ; then
      dlog "installing" "brewfile"
      brew bundle install --global
    fi

    dlog "upgrading" "brew"
    brew upgrade
  fi
}

brew_uninstall() {
  brew_env

  if [ -x "$(command -v brew)" ]; then
    if prompt "Uninstall Homebrew?" ; then
      dlog "uninstalling" "brew"
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
    fi
  fi
}
