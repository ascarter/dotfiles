if (( $+commands[codex] )); then
  if [[ -o interactive ]]; then
    source <(codex completion zsh)
  fi
fi
