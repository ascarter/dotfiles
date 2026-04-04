# Julia interactive setup (completions).
# Exports and PATH are in env.d/julia.zsh.
if (( $+commands[juliaup] )); then
  source <(juliaup completions zsh)
fi
