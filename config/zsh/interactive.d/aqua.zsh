# Aqua — workstation CLI tool manager

export AQUA_ROOT_DIR=${AQUA_ROOT_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/aquaproj-aqua}
export AQUA_GLOBAL_CONFIG=${AQUA_GLOBAL_CONFIG:-}:${XDG_CONFIG_HOME:-$HOME/.config}/aquaproj-aqua/aqua.yaml
export AQUA_REMOVE_MODE=pl
export AQUA_DISABLE_LAZY_INSTALL=true

if [[ -d "${AQUA_ROOT_DIR}/bin" ]]; then
  path=("${AQUA_ROOT_DIR}/bin" $path)

  if [[ -o interactive ]] && (( $+commands[aqua] )); then
    source <(aqua completion zsh)
  fi
fi
