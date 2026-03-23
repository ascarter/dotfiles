export JULIAUP_HOME="${XDG_DATA_HOME}"/juliaup
export JULIAUP_DEPOT_PATH="${XDG_DATA_HOME}"/julia

# Julia shell configuration
if [[ -d ${JULIAUP_HOME} ]]; then
  path=(${JULIAUP_HOME}/bin $path)
  export PATH
fi

# Enable shell completions for juliaup
if (( $+commands[juliaup] )); then
  source <(juliaup completions zsh)
fi
