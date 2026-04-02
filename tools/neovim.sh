# NeoVim (brew on macOS, GitHub release on Linux)

TOOL_CMD=nvim
TOOL_TYPE=github
TOOL_REPO=neovim/neovim
TOOL_BREW=neovim
TOOL_ASSET_LINUX_ARM64="nvim-linux-arm64.tar.gz"
TOOL_ASSET_LINUX_AMD64="nvim-linux-x86_64.tar.gz"
TOOL_STRIP_COMPONENTS=1
TOOL_LINKS=(bin/nvim:bin/nvim)
TOOL_MAN_PAGES=(share/man/man1/nvim.1)

tool_platform_check() {
  case "$(uname -s)" in
    Darwin) log "nvim" "not found. Run: brew install neovim"; exit 1 ;;
    Linux)  ;;
    *)      error "Unsupported OS: $(uname -s)"; return 1 ;;
  esac
}
