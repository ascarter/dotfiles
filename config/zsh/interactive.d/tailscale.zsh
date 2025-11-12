# Tailscale shell configuration

if [[ -o interactive ]] && (( $+commands[tailscale] )); then
  eval "$(tailscale completion zsh)"
fi
