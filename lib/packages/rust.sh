#!/bin/sh

set -eu

RUSTUP_HOME="${XDG_DATA_HOME}/rustup"
CARGO_HOME="${XDG_DATA_HOME}/cargo"

install() {
  if ! command -v rustup >/dev/null 2>&1; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | RUSTUP_HOME="${RUSTUP_HOME}" CARGO_HOME="${CARGO_HOME}" sh -s -- -y --no-modify-path --component rust-analyzer
  fi

  if [ -d "${CARGO_HOME}" ]; then
    . "${CARGO_HOME}/env"
    rustup show
  fi
}

uninstall() {
  if command -v rustup >/dev/null 2>&1; then
    rustup self uninstall
  fi
}

info() {
  if command -v rustup >/dev/null 2>&1; then
    rustup show
  else
    echo "Rust is not installed."
  fi
}

doctor() {
  info
}
