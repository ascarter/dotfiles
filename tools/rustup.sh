# rustup — Rust toolchain manager
TOOL_CMD=rustup
TOOL_TYPE=installer
TOOL_UPGRADE_COMMAND="rustup self update"
TOOL_INSTALL_URL="https://sh.rustup.rs"
TOOL_INSTALL_ARGS="-y --no-modify-path"

tool_uninstall() {
  command -v rustup >/dev/null 2>&1 || return 0
  rustup self uninstall -y
}
