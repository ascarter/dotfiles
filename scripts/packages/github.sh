#!/bin/sh

set -eu

install() {
  # Install GitHub CLI
  case $(uname -s) in
  Darwin)
    brew install gh
    brew install --cask github
    ;;
  Linux)
    if [ -f /etc/os-release ]; then
      . /etc/os-release
      case "${ID}" in
      fedora)
        case "${VARIANT_ID}" in
        silverblue | cosmic-atomic)
          if ! [ -f /etc/yum.repos.d/gh-cli.repo ]; then
            sudo curl -L -o /etc/yum.repos.d/gh-cli.repo https://cli.github.com/packages/rpm/gh-cli.repo
          fi
          if ! rpm -q gh; then
            rpm-ostree install -y gh
          fi
          ;;
        *)
          # DNF5 installation commands
          sudo dnf install dnf5-plugins git
          sudo dnf config-manager addrepo --overwrite --from-repofile=https://cli.github.com/packages/rpm/gh-cli.repo
          sudo dnf install gh --repo gh-cli
          ;;
        esac
        ;;
      debian | ubuntu)
        sudo apt-get install -y curl gpg
        curl -sS https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo gpg --dearmor /usr/share/keyrings/githubcli-archive-keyring.gpt
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list
        sudo apt-get update && sudo apt-get install -y gh
        ;;
      *) echo "Unknown Linux ${ID}" ;;
      esac
    fi
    ;;
  *) echo "unknown" ;;
  esac

  # GitHub CLI extensions installer
  if command -v gh >/dev/null 2>&1; then
    echo "Install gh extensions"
    gh auth status || true
    for extension in github/gh-copilot; do
      echo "GitHub CLI extension ${extension}"
      gh extension install ${extension} || true
    done

    # 1Password CLI
    if command -v op >/dev/null 2>&1; then
      op plugin init gh
      op plugin inspect gh
    fi
  fi
}

uninstall() {
  # GitHub CLI extensions installer
  if command -v gh >/dev/null 2>&1; then
    echo "Uninstall gh extensions"
    for extension in github/gh-copilot; do
      echo "GitHub CLI extension ${extension}"
      gh extension remove ${extension} || true
    done

    # 1Password CLI
    if command -v op >/dev/null 2>&1; then
      op plugin clear gh
    fi
  fi

  # Uninstall GitHub CLI
  case $(uname -s) in
  Darwin)
    brew uninstall gh
    brew uninstall --cask github
    ;;
  Linux)
    if [ -f /etc/os-release ]; then
      . /etc/os-release
      case "${ID}" in
      fedora)
        case "${VARIANT_ID}" in
        silverblue | cosmic-atomic)
          if rpm -q gh; then
            rpm-ostree uninstall -y gh
          fi
          if [ -f /etc/yum.repos.d/gh-cli.repo ]; then
            rm /etc/yum.repos.d/gh-cli.repo
          fi
          ;;
        *)
          # DNF5 installation commands
          sudo dnf uninstall gh --repo gh-cli
          ;;
        esac
        ;;
      debian | ubuntu)
        sudo apt-get uninstall -y gh
        sudo rm /usr/share/keyrings/githubcli-archive-keyring.gpt
        sudo rm /etc/apt/sources.list.d/github-cli.list
        ;;
      *) echo "Unknown Linux ${ID}" ;;
      esac
    fi
    ;;
  *) echo "unknown" ;;
  esac
}

info() {
  if command -v gh >/dev/null 2>&1; then
    gh --version
  else
    echo "GitHub is not installed."
  fi
}

doctor() {
  info
}
