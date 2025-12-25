export FNM_DIR="${FNM_DIR:-${XDG_DATA_HOME}/fnm}"

# Add fnm to PATH and configure shell integration
if (( $+commands[fnm] )); then
  eval "$(fnm completions --shell zsh)"

  # Ensure fnm has default Node.js installed before enabling shell integration.
  if fnm list | grep -q 'default'; then
    eval "$(fnm env --use-on-cd --version-file-strategy=recursive --corepack-enabled --shell zsh)"
  fi
fi
