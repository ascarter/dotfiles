UV_NO_MODIFY_PATH=1

if (( $+commands[uv] )); then
  if [[ -o interactive ]]; then
    eval "$(uv generate-shell-completion zsh)"
    eval "$(uvx --generate-shell-completion zsh)"
  fi
fi
