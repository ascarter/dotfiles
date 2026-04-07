RV_NO_MODIFY_PATH=1

if (( $+commands[rv] )); then
  if [[ -o interactive ]]; then
    eval "$(rv shell init zsh)"
    eval "$(rv shell completions zsh)"
  fi
fi
