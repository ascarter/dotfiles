zstyle ':completion:*' rehash true
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/zcompcache"

zstyle ':completion:*' completer _extensions _complete _approximate
zstyle ':completion:*' menu select
zstyle ':completion:*:*:*:*:descriptions' format '%F{green}-- %d --%f'
zstyle ':completion:*:*:*:*:corrections' format '%F{yellow}!- %d (errors: %e) -!%f'
zstyle ':completion:*:messages' format ' %F{purple}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{red}-- no matches found --%f'
zstyle ':completion:*' group-name ''
zstyle ':completion:*:*:-command-:*:*' group-order aliases builtins functions commands
zstyle ':completion:*' list-dirs-first true
zstyle ':completion:*' file-list all
zstyle ':completion:*' matcher-list \
  '' \
  'm:{a-zA-Z}={A-Za-z}' \
  'r:|[._-]=* r:|=*' \
  'l:|=* r:|=*'

# Generate completions only from available commands. A present command may
# still refuse to generate completions when its local state is unavailable, so
# never eval output from a failed call.
_load_generated_completion() {
  local generated
  generated="$("$@" 2>/dev/null)" || return 0
  [[ $generated == \#compdef* ]] || return 0
  eval "$generated"
}

if (( $+commands[mise] )); then
  _load_generated_completion mise completion zsh
fi

if (( $+commands[usage] )); then
  _load_generated_completion usage --completions zsh
fi

if (( $+commands[codex] )); then
  _load_generated_completion codex completion zsh
fi

if (( $+commands[pass-cli] )); then
  _load_generated_completion pass-cli completions zsh
fi

if (( $+commands[rv] )); then
  _load_generated_completion rv shell completions zsh
fi

if (( $+commands[rustup] )); then
  _load_generated_completion rustup completions zsh
fi

if (( $+commands[tailscale] )); then
  _load_generated_completion tailscale completion zsh
fi

if (( $+commands[uv] )); then
  _load_generated_completion uv generate-shell-completion zsh
fi

if (( $+commands[uvx] )); then
  _load_generated_completion uvx --generate-shell-completion zsh
fi

if (( $+commands[zed] )); then
  _load_generated_completion zed --completions zsh
fi

unfunction _load_generated_completion

# Cargo's completion belongs to the selected Rust toolchain. Resolve its
# sysroot on demand so changing projects also changes the completion version.
_cargo_toolchain_completion() {
  local completion
  completion="$(rustc --print sysroot 2>/dev/null)/share/zsh/site-functions/_cargo"
  [[ -r $completion ]] || return 1

  local fpath=("${completion:h}" $fpath)
  (( $+functions[_cargo] )) && unfunction _cargo
  autoload -Uz _cargo
  _cargo "$@"
}
compdef _cargo_toolchain_completion cargo
