# rustup — Rust toolchain manager
TOOL_CMD=rustup

tool_download() {
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
}

tool_uninstall() {
  command -v rustup >/dev/null 2>&1 || return 0
  rustup self uninstall -y
}
