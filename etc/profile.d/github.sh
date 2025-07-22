# GitHub CLI configuration

# Check if gh is installed and gh extension copilot is installed
if command -v gh >/dev/null 2>&1; then
  # GitHub aliases
  # Only load aliases in interactive Bash or Zsh, skip for /bin/sh
  if [ -n "$PS1" ] && command -v op >/dev/null 2>&1; then
    # Check if we're directly in bash or zsh (not just any shell with PS1 set)
    case "$SHELL" in
    *bash)
      if [ -n "$BASH_VERSION" ]; then
        if [ -f "${DOTFILES_CONFIG}/gh-copilot-bash.sh" ]; then
          . "${DOTFILES_CONFIG}/gh-copilot-bash.sh"
        else
          eval "$(gh copilot alias -- bash)"
        fi
      fi
      ;;
    *zsh)
      if [ -n "$ZSH_VERSION" ]; then
        if [ -f "${DOTFILES_CONFIG}/gh-copilot-zsh.sh" ]; then
          . "${DOTFILES_CONFIG}/gh-copilot-zsh.sh"
        else
          eval "$(gh copilot alias -- zsh)"
        fi
      fi
      ;;
    esac
  fi
fi

# vim: set ft=sh ts=2 sw=2 et:
