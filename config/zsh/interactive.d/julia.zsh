export JULIAUP_HOME="${XDG_DATA_HOME}"/juliaup
export JULIAUP_DEPOT_PATH="${XDG_DATA_HOME}"/julia

if [[ -d ${JULIAUP_HOME}/bin ]]; then
  path=(${JULIAUP_HOME}/bin $path)
fi

if (( $+commands[juliaup] )); then
  source <(juliaup completions zsh)
fi
