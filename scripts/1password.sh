#!/bin/sh

# 1Password install script

set -eu

op_container_sock=${HOME}/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock
op_agent_sock=${HOME}/.1password/agent.sock

case $(uname -s) in
Darwin)
  # Use homebrew to install 1Password
  if command -v brew >/dev/null 2>&1; then
    brew install --adopt --cask 1password
    brew install --cask 1password-cli

    # Symlink 1P agent socket to standard location ~/.1password/agent.sock
    if [ -S "${op_container_sock}" ] && ! [ -L "${op_agent_sock}" ]; then
      mkdir -p ${HOME}/.1password
      ln -s "${op_container_sock}" "${op_agent_sock}"
    fi
  else
    echo "Homebrew is not installed. Please install Homebrew first."
    exit 1
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
XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
dotfiles_ssh_config=${XDG_CONFIG_HOME}/ssh/config

if [ -S "${op_container_sock}" ]; then
  if ! [ -f ${HOME}/.ssh/config ] || ! grep -q -x "Include ${dotfiles_ssh_config}" ${HOME}/.ssh/config; then
    echo "Enable SSH IdentityAgent"
    mkdir -p ${HOME}/.ssh
    echo "Include ${dotfiles_ssh_config}" >>${HOME}/.ssh/config
  fi
fi

# 1Password CLI
if command -v op >/dev/null 2>&1; then
  if command -v gh >/dev/null 2>&1; then
    op plugin init gh
    if [ -f "${XDG_CONFIG_HOME}/op/plugins.sh" ]; then
      source "${XDG_CONFIG_HOME}/op/plugins.sh"
    fi
    op plugin inspect gh
  fi
fi

# vim: set ft=sh ts=2 sw=2 et:
