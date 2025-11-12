export UV_HOME="${XDG_DATA_HOME}"/uv
export UV_TOOL_DIR="${UV_HOME}"/tools
export UV_TOOL_BIN_DIR="${UV_HOME}"/bin

# Add uv tool bin directory to PATH
if (( $+commands[uv] )); then
  if [[ -d ${UV_TOOL_BIN_DIR} ]]; then
    path=("${UV_TOOL_BIN_DIR}" $path)
  fi
  eval "$(uv generate-shell-completion zsh)"
fi
