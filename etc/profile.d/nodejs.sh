export FNM_DIR="${FNM_DIR:-${XDG_DATA_HOME}/fnm}"

# Add fnm to PATH and configure shell integration
if [ -d "${FNM_DIR}" ] && [ -x "${FNM_DIR}/fnm" ]; then
  export PATH="${FNM_DIR}:$PATH"

  # Initialize fnm with shell integration
  if [ -n "$BASH_VERSION" ]; then
    eval "$(fnm env --use-on-cd --version-file-strategy=recursive --shell bash)"
    eval "$(fnm completions --shell bash)"
  elif [ -n "$ZSH_VERSION" ]; then
    eval "$(fnm env --use-on-cd --version-file-strategy=recursive --shell zsh)"
    eval "$(fnm completions --shell zsh)"
  fi
fi
