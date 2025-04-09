#!/bin/sh

# Setup Tailscale for host

set -eu

case $(uname -s) in
Darwin)
  # Check if homebrew is installed. If it is, use homebrew to install Tailscale
  if command -v brew > /dev/null 2>&1; then
    brew install tailscale
  else
    echo "Homebrew is not installed. Please install Homebrew first."
  fi
  ;;
Linux)
  if [ -f /etc/os-release ]; then
    . /etc/os-release
  fi

  case "$ID" in
  fedora)
    case "${VARIANT_ID}" in
    silverblue)
      if ! [ -f /etc/yum.repos.d/tailscale.repo ]; then
        sudo curl -L -o /etc/yum.repos.d/tailscale.repo https://pkgs.tailscale.com/stable/fedora/tailscale.repo
      fi
      
      if ! rpm -q tailscale; then
        rpm-ostree install -y tailscale
      if
      ;;
    *)
      sudo dnf config-manager addrepo --overwrite --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo
      sudo dnf install tailscale
      ;;
    esac

    # Enable tailscale
    if command -v tailscaled > /dev/null 2>&1; then
      systemctl enable --now tailscaled
    fi
    ;;
  debian | ubuntu)
    curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
    curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list
    sudo apt-get upgrade && sudo apt-get update -y
    sudo apt-get install -y tailscale
    ;;
esac

  if command -v tailscaled > /dev/null 2>&1; then
    sudo tailscale up --ssh --accept-routes --operator=$USER --reset
    tailscale ip -4
  fi
  ;;
esac
