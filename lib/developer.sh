# Developer tools

# Rust
rustup_install() {
  if [ ! -x "$(command -v rustup)" ]; then
    dlog "install" "rustup"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path --component rust-analyzer
  else
    dlog "exist" "rustup"
  fi

  if [[ -d ${HOME}/.cargo ]]; then
    source "$HOME/.cargo/env"
  fi
}

rustup_update() {
  if [ -x "$(command -v rustup)" ]; then
    dlog "update" "rustup"
    rustup update
  fi
}

rustup_uninstall() {
  if [ -x "$(command -v rustup)" ]; then
    dlog "uninstall" "rustup"
    rustup self uninstall
  fi
}

rustup_list() {
  if [ -x "$(command -v rustc)" ]; then
    dlog "rustup" "$(RUSTUP_LOG=ERROR rustup --version)"
  fi
}

developer_install() {
  tlog "install" "developer"
  rustup_install
}

developer_update() {
  tlog "update" "developer"
  rustup_update
}

developer_uninstall() {
  tlog "uninstall" "developer"
  rustup_uninstall
}

developer_list() {
  tlog "status" "developer"
  rustup_list
}
