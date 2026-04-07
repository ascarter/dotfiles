export FNM_DIR="${FNM_DIR:-${XDG_DATA_HOME}/fnm}"

# Add fnm default Node.js to PATH (stable path, no subprocess).
if [[ -d ${FNM_DIR}/aliases/default/bin ]]; then
  path=(${FNM_DIR}/aliases/default/bin $path)
fi

# Shell integration (completions, automatic version switching).
if (( $+commands[fnm] )); then
  if [[ -o interactive ]]; then
    eval "$(fnm completions --shell zsh)"

    if fnm list | grep -q 'default'; then
      eval "$(fnm env --use-on-cd --version-file-strategy=recursive --corepack-enabled --shell zsh)"
    fi
  fi
fi
