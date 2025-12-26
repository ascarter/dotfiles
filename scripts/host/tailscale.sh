#!/bin/sh

# Tailscale installation script

set -eu

if command -v tailscale >/dev/null 2>&1; then
  echo "Tailscale is already installed."
  exit 0
fi

case "$(uname -s)" in
  Darwin)
    echo "Use Homebrew to install Tailscale on macOS"
    echo "brew install --cask tailscale-app"
    exit 0
    ;;
  Linux)
    if [ -f /etc/os-release ]; then
      . /etc/os-release
      case "${ID}" in
        ubuntu | debian) ;;
        fedora)
          echo "Fedora ${VARIANT_ID} detected"

          TAILSCALE_URL=https://pkgs.tailscale.com/stable/fedora/tailscale.repo
          TAILSCALE_REPO_PATH=/etc/yum.repos.d/tailscale.repo
          if [ ! -f "${TAILSCALE_REPO_PATH}" ]; then
            curl -fsSL "${TAILSCALE_URL}" | sudo tee ${TAILSCALE_REPO_PATH}
          fi

          case "${VARIANT_ID}" in
            silverblue | cosmic-atomic)
              rpm-ostree refresh-md
              rpm-ostree install tailscale
              ;;
            *)
              sudo dnf install -y tailscale
              ;;
          esac

          echo "Please reboot to complete the installation."
          echo "Run 'systemctl enable --now tailscaled' after reboot."
          echo "Run 'sudo tailscale up' to connect."
          ;;
        *)
          echo "Unsupported Linux distribution ${ID}"
          ;;
      esac
    else
      echo "Unsupported Linux distribution"
    fi
    ;;
  *)
    echo "unknown"
    ;;
esac

echo "Tailscale installed."
