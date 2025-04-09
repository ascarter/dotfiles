#!/bin/sh

set -eu

XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}

# Rust
echo "Configuring Rust (rustup)"
if ! command -v rustup > /dev/null 2>&1; then
  echo "Install rustup"
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path --component rust-analyzer
fi

if [ -d "${HOME}/.cargo" ]; then
  # Use . instead of source for POSIX compatibility
  . "$HOME/.cargo/env"
  rustup show
fi

# Rustup
if command -v rustup >/dev/null 2>&1; then
  echo "Update completions"
  completion_dir="${HOME}/.local/share/zsh/functions"
  mkdir -p "${completion_dir}"

  echo "Generating completion for rust"
  rustup completions zsh > "${completion_dir}/_rustup"
  rustup completions zsh cargo > "${completion_dir}/_cargo"
fi

print "Rust setup complete"