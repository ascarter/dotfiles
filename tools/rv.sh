# rv — Ruby version manager
TOOL_CMD=rv

tool_download() {
  curl -LsSf https://rv.dev/install | RV_NO_MODIFY_PATH=1 sh
}
