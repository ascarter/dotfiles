# rustup — Rust toolchain manager
TOOL_CMD=rustup

tool_download() {
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
}
