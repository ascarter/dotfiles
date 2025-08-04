# GitHub CLI configuration

# Only load aliases in interactive shell
if [ -n "$PS1" ] && command -v gh >/dev/null 2>&1; then
  # Generate GitHub Copilot aliases
  if gh extension list | grep -q copilot; then
    case "$SHELL" in
    *bash)
      if [ -n "$BASH_VERSION" ]; then
        eval "$(gh copilot alias -- bash)"
      fi
      ;;
    *zsh)
      if [ -n "$ZSH_VERSION" ]; then
        eval "$(gh copilot alias -- zsh)"
      fi
      ;;
    esac
  fi
fi
