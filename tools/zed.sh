# zed — code editor
TOOL_CMD=zed
TOOL_TYPE=installer
TOOL_INSTALL_URL="https://zed.dev/install.sh"

tool_externally_managed() {
  return 0
}

tool_uninstall() {
  zed --uninstall
}
