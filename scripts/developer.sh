#!/bin/sh

# Developer provisioning script

# Rust
if command -v rustup >/dev/null 2>&1; then
  # Initialize default toolchain if not installed
  if ! rustup show active-toolchain; then
    rustup-init -y --no-modify-path --component rust-analyzer
    . "$CARGO_HOME/env"
  fi
fi

# Ruby
if command -v rbenv >/dev/null 2>&1; then
  # Install latest Ruby and enable YJIT
  export RUBY_CONFIGURE_OPTS="--enable-yjit"
  ruby_ver=3.4.3

  if ! rbenv versions | grep $ruby_ver; then
    rbenv install 3.4.3
  fi
fi

# vim: set ft=sh ts=2 sw=2 et:
