# claude — Claude Code CLI
TOOL_CMD=claude
TOOL_TYPE=installer
TOOL_UPGRADE_COMMAND="claude update"
TOOL_INSTALL_URL="https://claude.ai/install.sh"

tool_uninstall() {
  rm -f "${HOME}/.local/bin/claude"
  rm -rf "${HOME}/.local/share/claude"
}
