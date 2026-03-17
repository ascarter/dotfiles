# zed — code editor
TOOL_CMD=zed

tool_download() {
  curl -f https://zed.dev/install.sh | sh
}

tool_upgrade() {
  TOOLS_INSTALL_SKIPPED=1
  log "skip" "zed updates itself in-app"
}

tool_uninstall() {
  zed --uninstall
}
