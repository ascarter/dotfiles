#!/bin/sh

# Tailscale installation script

set -eu

case "$(uname -s)" in
  Darwin)
    if command -v tailscale >/dev/null 2>&1; then
      echo "Tailscale is already installed."
    else
      echo "Use Homebrew to install Tailscale on macOS"
      brew install --cask tailscale-app
    fi
    ;;
  Linux)
    if [ -f /etc/os-release ]; then
      . /etc/os-release
      case "${ID}" in
        ubuntu | debian) ;;
        fedora)
          echo "Fedora ${VARIANT_ID} detected"

          if command -v tailscale >/dev/null 2>&1; then
            echo "Tailscale is already installed."

            # Verify that tailscale is enabled
            if ! tailscale status; then
              systemctl enable --now tailscaled
              sudo tailscale up --accept-routes=true --ssh
            fi
          else
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

            echo "Reboot to complete the installation."
            echo "After reboot, run the following or rerun this script:"
            echo ""
            echo "systemctl enable --now tailscaled"
            echo "sudo tailscale up --accept-routes=true --ssh"
          fi
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
