# uv — Python package manager
TOOL_CMD=uv

tool_download() {
  curl -LsSf https://astral.sh/uv/install.sh | UV_NO_MODIFY_PATH=1 sh
}
