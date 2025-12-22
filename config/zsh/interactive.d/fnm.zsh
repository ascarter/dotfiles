export FNM_DIR="${FNM_DIR:-${XDG_DATA_HOME}/fnm}"

# Add fnm to PATH and configure shell integration
if (( $+commands[fnm] )); then
  eval "$(fnm env --use-on-cd --version-file-strategy=recursive --corepack-enabled --shell zsh)"
  eval "$(fnm completions --shell zsh)"
fi
