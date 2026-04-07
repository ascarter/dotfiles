if (( $+commands[fzf] )); then
  if [[ -o interactive ]]; then
    source <(fzf --zsh)
  fi
fi
