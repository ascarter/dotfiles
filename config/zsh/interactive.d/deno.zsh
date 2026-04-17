# Deno shell completions

if [[ -o interactive ]] && (( $+commands[deno] )); then
  eval "$(deno completions zsh)"
fi
