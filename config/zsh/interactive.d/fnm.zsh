# Shell integration for fnm (completions, automatic version switching).
# Exports and default-Node PATH are in env.d/fnm.zsh.
if (( $+commands[fnm] )); then
  eval "$(fnm completions --shell zsh)"

  # Ensure fnm has default Node.js installed before enabling shell integration.
  if fnm list | grep -q 'default'; then
    eval "$(fnm env --use-on-cd --version-file-strategy=recursive --corepack-enabled --shell zsh)"
  fi
fi
