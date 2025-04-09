#!/bin/sh

# 1Password install script

set -eu

XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}

case $(uname -s) in
Darwin)
  # Check if homebrew is installed. If it is, use homebrew to install 1Password
  if command -v brew >/dev/null 2>&1; then
    brew install --cask 1password 1password-cli
    if [ -S ${HOME}/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock ] && ! [ -L ~/.1password/agent.sock ]; then
      echo "symlink ~/.1password/agent.sock"
      mkdir -p ~/.1password
      ln -s ~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock ~/.1password/agent.sock
    fi
  else
    echo "Homebrew is not installed. Please install Homebrew first."
  fi
  ;;
Linux)
  if [ -f /etc/os-release ]; then
    . /etc/os-release
  fi

  case $ID in
  fedora)
    # Add 1Password repository
    if ! [ -f /etc/yum.repos.d/1password.repo ]; then
      sudo sh -c 'echo -e "[1password]\nname=1Password Stable Channel\nbaseurl=https://downloads.1password.com/linux/rpm/stable/\$basearch\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://downloads.1password.com/linux/keys/1password.asc" > /etc/yum.repos.d/1password.repo'
    fi
    # On Fedora Silverblue, use rpm-ostree to overlay 1Password
    if [ "$VARIANT_ID" = "silverblue" ]; then
      rpm-ostree install --idempotent -y 1password 1password-cli
    else
      sudo dnf install 1password 1password-cli
    fi
    ;;
  debian | ubuntu)
    arch=$(dpkg --print-architecture)
    sudo apt-get install -y curl gpg
    curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
    echo "deb [arch=${arch} signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/${arch} stable main" | sudo tee /etc/apt/sources.list.d/1password.list
    sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
    curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol
    sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
    curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg
    sudo apt-get update && sudo apt-get install -y 1password 1password-cli
    ;;
  esac
  ;;
esac

# Configure 1P SSH
if [ -L ~/.1password/agent.sock ]; then
  if ! [ -f ~/.ssh/config ] || ! grep -q -x "Include ~/.config/ssh/config" ~/.ssh/config; then
    echo "Enable SSH IdentityAgent"
    mkdir -p ~/.ssh
    echo "Include ~/.config/ssh/config" >>~/.ssh/config
  fi
fi
