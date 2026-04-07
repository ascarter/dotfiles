# Aqua — workstation CLI tool manager

export AQUA_GLOBAL_CONFIG=${AQUA_GLOBAL_CONFIG:-}:${XDG_CONFIG_HOME:-$HOME/.config}/aquaproj-aqua/aqua.yaml
export AQUA_DISABLE_LAZY_INSTALL=true

if (( $+commands[aqua] )); then
  path=("$(aqua root-dir)/bin" $path)

  if [[ -o interactive ]]; then
    source <(aqua completion zsh)
  fi
fi
