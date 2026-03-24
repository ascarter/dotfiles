# rv — Ruby version manager
TOOL_CMD=rv
TOOL_TYPE=installer
TOOL_UPGRADE_COMMAND="rv selfupdate"

tool_download() {
  curl -LsSf https://rv.dev/install | RV_NO_MODIFY_PATH=1 sh
}
