# claude — Claude Code CLI
TOOL_CMD=claude
TOOL_TYPE=installer
TOOL_UPGRADE_COMMAND="claude update"

tool_download() {
  curl -fsSL https://claude.ai/install.sh | bash
}

tool_uninstall() {
  rm -f "${HOME}/.local/bin/claude"
  rm -rf "${HOME}/.local/share/claude"
}
