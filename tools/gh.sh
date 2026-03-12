# gh — GitHub CLI
TOOL_CMD=gh

tool_platform_check() {
  case "$(uname -s)" in
    Darwin)
      log "gh" "not found. Run: brew install gh"
      exit 1
      ;;
  esac
}

tool_download() {
  [ -f /etc/os-release ] || { error "Unsupported Linux distribution (missing /etc/os-release)"; return 1; }
  . /etc/os-release

  case "${ID:-}" in
    fedora)
      bash "${DOTFILES_HOME}/lib/os/fedora/repo.sh" \
        "https://cli.github.com/packages/rpm/gh-cli.repo" \
        "/etc/yum.repos.d/github-cli.repo"
      bash "${DOTFILES_HOME}/lib/os/fedora/pkg.sh" install gh
      ;;
    *)
      error "Unsupported Linux distribution: ${ID:-unknown}"; return 1
      ;;
  esac
}
