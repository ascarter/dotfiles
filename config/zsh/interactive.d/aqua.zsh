# Aqua — workstation CLI tool manager

local aqua_root="${XDG_DATA_HOME}/aquaproj-aqua"

if [[ -d "${aqua_root}" ]]; then
  export AQUA_GLOBAL_CONFIG="${XDG_CONFIG_HOME}/aquaproj-aqua/aqua.yaml"
  export AQUA_ROOT_DIR="${aqua_root}"
  export AQUA_DISABLE_LAZY_INSTALL=true
  path=("${AQUA_ROOT_DIR}/bin" $path)
fi

# Completions
if (( $+commands[aqua] )); then
  source <(aqua completion zsh)
fi
