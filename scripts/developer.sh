#!/bin/sh

set -euo pipefail

# Developer tools

# Rust
if [ ! -x "$(command -v rustup)" ]; then
  echo "Install rustup"
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path --component rust-analyzer
fi

if [[ -d ${HOME}/.cargo ]]; then
  source "$HOME/.cargo/env"
  rustup show
fi
