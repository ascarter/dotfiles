# Tailscale shell configuration

# completions
if [ -n "$PS1" ] && command -v tailscale >/dev/null 2>&1; then
  case "$SHELL" in
  *bash)
    if [ -n "$BASH_VERSION" ]; then
      source <(tailscale completion bash)
    fi
    ;;
  *zsh)
    if [ -n "$ZSH_VERSION" ]; then
      eval "$(tailscale completion zsh)"
    fi
    ;;
  esac
fi

# vim: set ft=sh ts=2 sw=2 et:
