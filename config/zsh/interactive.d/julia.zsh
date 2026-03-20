export JULIAUP_DEPOT_PATH="${XDG_DATA_HOME}"/julia
export JULIA_DEPOT_PATH="${XDG_DATA_HOME}"/julia

# Enable shell completions for juliaup
if (( $+commands[juliaup] )); then
  source <(juliaup completions zsh)
fi
