# copilot-cli — GitHub Copilot CLI
TOOL_CMD=copilot
TOOL_TYPE=github
TOOL_REPO=github/copilot-cli
TOOL_ASSET_MACOS_ARM64="copilot-darwin-arm64.tar.gz"
TOOL_ASSET_LINUX_ARM64="copilot-linux-arm64.tar.gz"
TOOL_ASSET_LINUX_AMD64="copilot-linux-x64.tar.gz"
TOOL_LINKS=(copilot)

tool_upgrade() {
  copilot update
}
