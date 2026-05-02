# Proton shell configuration

if (( $+commands[pass-cli] )); then
  if [[ -o interactive ]]; then
    eval "$(pass-cli completions zsh)"
  fi
fi
