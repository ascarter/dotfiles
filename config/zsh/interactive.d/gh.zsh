# GitHub CLI shell configuration

if (( $+commands[gh] )); then
  export GITHUB_TOKEN=$(gh auth token 2>/dev/null)

  if [[ -o interactive ]]; then
    eval "$(gh completion -s zsh)"
  fi
fi
