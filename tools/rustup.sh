# rustup — Rust toolchain manager
TOOL_CMD=rustup
TOOL_TYPE=installer
TOOL_UPGRADE_COMMAND="rustup self update"

tool_download() {
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
}

tool_uninstall() {
  command -v rustup >/dev/null 2>&1 || return 0
  rustup self uninstall -y
}
