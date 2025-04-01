#!/bin/sh

set -euo pipefail

XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}

# 1Password CLI
if [ -x "$(command -v op)" ]; then
  for plugin in gh; do
    echo "Init 1Password CLI plugin ${plugin}"
    op plugin init ${plugin}
    op plugin inspect ${plugin}
  done

  if [ -f "${XDG_CONFIG_HOME}/op/plugins.sh" ]; then
    echo "Enabling 1Password CLI plugins"
    source "${XDG_CONFIG_HOME}/op/plugins.sh"
  fi
fi

# Configure 1P SSH
if [ -S ${HOME}/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock ] && ! [ -L ~/.1password/agent.sock ]; then
  echo "symlink ~/.1password/agent.sock"
  mkdir -p ~/.1password
  ln -s ~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock ~/.1password/agent.sock
fi

if [ -L ~/.1password/agent.sock ]; then
  if ! [ -f ~/.ssh/config ] || ! grep -q -x "Include ~/.config/ssh/config" ~/.ssh/config; then
    echo "Enable SSH IdentityAgent"
    mkdir -p ~/.ssh
    echo "Include ~/.config/ssh/config" >>~/.ssh/config
  fi
fi

# GitHub CLI extensions installer
if type gh >/dev/null 2>&1; then
  echo "Install gh extensions"
  gh auth status || true
  for extension in github/gh-copilot; do
    echo "GitHub CLI extension ${extension}"
    gh extension install ${extension} || true
  done
fi

# Developer tools

# Ruby
echo "Configuring Ruby (rbenv)"
curl -fsSL https://rbenv.org/install.sh | bash
echo

# Rust
echo "Configuring Rust (rustup)"
if [ ! -x "$(command -v rustup)" ]; then
  echo "Install rustup"
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path --component rust-analyzer
fi

if [[ -d ${HOME}/.cargo ]]; then
  source "$HOME/.cargo/env"
  rustup show
fi

# Generate completions
echo "Update completions"
completion_dir="${HOME}/.local/share/zsh/functions"
mkdir -p ${completion_dir}

# Docker
if command -v docker >/dev/null 2>&1; then
  echo "Generate completion for docker"
  eval "docker completion zsh" >${completion_dir}/_docker
fi

# Rustup
if command -v rustup >/dev/null 2>&1; then
  echo "Generating completion for rust"
  eval "rustup completions zsh" >${completion_dir}/_rustup
  eval "rustup completions zsh cargo" >${completion_dir}/_cargo
fi
