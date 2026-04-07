# Tailscale shell configuration

if (( $+commands[tailscale] )); then
  if [[ -o interactive ]]; then
    eval "$(tailscale completion zsh)"
  fi
fi
