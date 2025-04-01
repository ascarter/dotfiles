#!/bin/sh

set -euo pipefail

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
