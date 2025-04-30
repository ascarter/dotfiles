#!/bin/sh

# 1Password install script

set -eu

install() {
  case $(uname -s) in
  Darwin)
    # Check if homebrew is installed. If it is, use homebrew to install 1Password
    if command -v brew >/dev/null 2>&1; then
      if ! [ -d /Applications/1Password.app ]; then
        brew install --cask 1password
      fi
      brew install --cask 1password-cli
      if [ -S ${HOME}/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock ] && ! [ -L ${HOME}/.1password/agent.sock ]; then
        mkdir -p ${HOME}/.1password
        ln -s ${HOME}/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock ${HOME}/.1password/agent.sock
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

      case "${VARIANT_ID}" in
      silverblue | comsic-atomic)
        if ! rpm -q 1password; then
          rpm-ostree install -y 1password
        fi
        if ! rpm -q 1password-cli; then
          rpm-ostree install -y 1password-cli
        fi
        ;;
      *)
        if ! dnf list installed 1password; then
          sudo dnf install 1password
        fi
        if ! dnf list installed 1password-cli; then
          sudo dnf install 1password-cli
        fi
        ;;
      esac
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
  if [ -S ${HOME}/.1password/agent.sock ]; then
    if ! [ -f ${HOME}/.ssh/config ] || ! grep -q -x "Include ${HOME}/.config/ssh/config" ${HOME}/.ssh/config; then
      echo "Enable SSH IdentityAgent"
      mkdir -p ${HOME}/.ssh
      echo "Include ${HOME}/.config/ssh/config" >>${HOME}/.ssh/config
    fi
  fi
}

uninstall() {
  case $(uname -s) in
  Darwin)
    # Check if homebrew is installed
    if command -v brew >/dev/null 2>&1; then
      brew uninstall --cask 1password 1password-cli
    fi

    if [ -d ${HOME}/.1password ]; then
      echo "Remove ${HOME}/.1password"
      rm -rf ${HOME}/.1password
    fi
    ;;
  Linux)
    if [ -f /etc/os-release ]; then
      . /etc/os-release
    fi

    case $ID in
    fedora)
      case "$VARIANT_ID" in
      silverblue | cosmic-atomic)
        if rpm -q 1password; then
          rpm-ostree uninstall -y 1password
        fi
        if rpm -q 1password-cli; then
          rpm-ostree uninstall -y 1password-cli
        fi
        ;;
      *)
        if dnf list installed 1password; then
          sudo dnf uninstall 1password
        fi
        if dnf list installed 1password-cli; then
          sudo dnf uninstall 1password-cli
        fi
        ;;
      esac

      # Remove 1Password repository
      if [ -f /etc/yum.repos.d/1password.repo ]; then
        sudo rm /etc/yum.repos.d/1password.repo
      fi
      ;;
    debian | ubuntu)
      sudo apt-get uninstall -y 1password 1password-cli
      sudo rm -rf /usr/share/debsig/keyrings/AC2D62742012EA22
      sudo rm -rf /etc/debsig/policies/AC2D62742012EA22/
      sudo rm -rf /etc/apt/sources.list.d/1password.list
      sudo rm -rf /usr/share/keyrings/1password-archive-keyring.gpg
      ;;
    esac
    ;;
  esac
}

info() {
  if command -v op >/dev/null 2>&1; then
    op -v
    op account list
  else
    echo "1Password is not installed"
  fi
}

doctor() {
  info
}
