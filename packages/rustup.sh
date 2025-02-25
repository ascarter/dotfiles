install() {
  if command -v rustup 1>/dev/null 2>&1; then
    echo "rustup already installed"
    exit 1
  fi

  dlog "rustup" "installing"
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --no-modify-path --component rust-analyzer
  if [ -x ${HOME}/.cargo/bin/rustup ]; then
    ${HOME}/.cargo/bin/rustup --version
  fi
}

uninstall() {
  if ! command -v rustup 1>/dev/null 2>&1; then
    echo "rustup not installed"
    exit 1
  fi

  dlog "rustup" "uninstalling"
  rustup self uninstall
}

list() {
  if command -v rustup 1>/dev/null 2>&1; then
    rustup show
  else
    echo "rustup not installed"
    exit 1
  fi
}
