# claude — Claude Code CLI
TOOL_CMD=claude
TOOL_TYPE=installer

tool_download() {
  curl -fsSL https://claude.ai/install.sh | bash
}

tool_upgrade() {
  claude update
}

tool_uninstall() {
  rm -f "${HOME}/.local/bin/claude"
  rm -rf "${HOME}/.local/share/claude"
}
