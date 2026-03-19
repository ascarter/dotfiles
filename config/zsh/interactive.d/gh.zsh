# GitHub CLI shell configuration

if [[ -o interactive ]] && (( $+commands[gh] )); then
  eval "$(gh completion -s zsh)"
fi
