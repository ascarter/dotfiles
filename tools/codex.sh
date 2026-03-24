# codex — OpenAI Codex CLI
TOOL_CMD=codex
TOOL_TYPE=github
TOOL_REPO=openai/codex

tool_download() {
  local asset

  case "$(uname -s):$(uname -m)" in
    Darwin:arm64|Darwin:aarch64)
      asset="codex-aarch64-apple-darwin.tar.gz"
      ;;
    Linux:arm64|Linux:aarch64)
      asset="codex-aarch64-unknown-linux-musl.tar.gz"
      ;;
    Linux:x86_64|Linux:amd64)
      asset="codex-x86_64-unknown-linux-musl.tar.gz"
      ;;
    *)
      error "Unsupported platform: $(uname -s):$(uname -m)"
      return 1
      ;;
  esac

  tool_gh_install "$TOOL_REPO" "$asset"
}

tool_post_install() {
  local binary
  binary="$(find "$TOOLS_INSTALL_DIR" -maxdepth 1 -type f -name 'codex-*' | head -n1)"
  [[ -n "$binary" ]] || { error "tool_post_install: extracted Codex binary not found in ${TOOLS_INSTALL_DIR}"; return 1; }

  ln -sf "$binary" "${XDG_OPT_BIN}/codex"
}
