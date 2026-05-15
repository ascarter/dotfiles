export UV_NO_MODIFY_PATH=1
export UV_PYTHON_BIN_DIR="$XDG_DATA_HOME/uv/bin"

path=(${UV_PYTHON_BIN_DIR} $path)

if (( $+commands[uv] )); then
  if [[ -o interactive ]]; then
    eval "$(uv generate-shell-completion zsh)"
    eval "$(uvx --generate-shell-completion zsh)"
  fi
fi
