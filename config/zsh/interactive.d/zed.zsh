# Zed shell configuration

if (( $+commands[zed] )); then
  if [[ -o interactive ]]; then
    eval "$(zed --completions zsh)"
  fi
fi
