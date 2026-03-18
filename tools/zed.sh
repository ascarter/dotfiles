# zed — code editor
TOOL_CMD=zed

tool_externally_managed() {
  return 0
}

tool_download() {
  curl -f https://zed.dev/install.sh | sh
}

tool_uninstall() {
  zed --uninstall
}
