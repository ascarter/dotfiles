# Optional workstation applications. These guards do not install or require the
# commands; they only activate valid completions when an application is already
# available. A present application may still refuse to generate completions
# when its local state is unavailable, so never eval output from a failed call.

_load_generated_completion() {
  local generated
  generated="$("$@" 2>/dev/null)" || return 0
  [[ $generated == \#compdef* ]] || return 0
  eval "$generated"
}

if (( $+commands[codex] )); then
  _load_generated_completion codex completion zsh
fi

if (( $+commands[pass-cli] )); then
  _load_generated_completion pass-cli completions zsh
fi

if (( $+commands[tailscale] )); then
  _load_generated_completion tailscale completion zsh
fi

if (( $+commands[zed] )); then
  _load_generated_completion zed --completions zsh
fi

unfunction _load_generated_completion
