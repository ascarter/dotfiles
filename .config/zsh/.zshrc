# Interactive-shell configuration.

typeset -U fpath
fpath=(
  "$ZDOTDIR/functions"
  "${XDG_DATA_HOME}/zsh/site-functions"
  /opt/homebrew/share/zsh/site-functions
  $fpath
)
export FPATH

# Autoload functions. A local ~/.zshrc can add more functions later.
for function_file in "$ZDOTDIR"/functions/*(-.N); do
  autoload -Uz "${function_file:t}"
done

# Navigation and completion behavior.
setopt \
  ALWAYS_TO_END \
  AUTO_CD \
  AUTO_PUSHD \
  COMPLETE_ALIASES \
  COMPLETE_IN_WORD \
  EXTENDED_GLOB \
  GLOB_DOTS \
  PUSHD_IGNORE_DUPS \
  PUSHD_SILENT \
  RM_STAR_WAIT

# History is persistent user state, not configuration.
mkdir -p "$XDG_STATE_HOME/zsh" "$XDG_CACHE_HOME/zsh"
HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=10000
SAVEHIST=10000
setopt \
  APPEND_HISTORY \
  HIST_EXPIRE_DUPS_FIRST \
  HIST_FIND_NO_DUPS \
  HIST_IGNORE_ALL_DUPS \
  HIST_IGNORE_DUPS \
  HIST_REDUCE_BLANKS \
  HIST_VERIFY \
  SHARE_HISTORY

# Prompt.
autoload -Uz promptinit
promptinit
prompt source

# Completion.
autoload -Uz compinit
compinit -d "$XDG_CACHE_HOME/zsh/zcompdump-${HOST}-${ZSH_VERSION}"

# Root-level zsh files remain local and untracked.
# mise activation happens in local .zshrc
[[ -r "$HOME/.zshrc" ]] && source "$HOME/.zshrc"

# dircolors
if [[ -f "$ZDOTDIR/dircolors" ]] && (( $+commands[coreutils] )); then
  eval "$(coreutils dircolors "$ZDOTDIR/dircolors")"
fi

# Editor preference
if (( $+commands[nvim] )); then
  export EDITOR=nvim
elif (( $+commands[vim] )); then
  export EDITOR=vim
else
  export EDITOR=vi
fi

export VISUAL="$EDITOR"

# Keybindings
bindkey -e

autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

bindkey '^[h' backward-char
bindkey '^[j' down-line-or-history
bindkey '^[k' up-line-or-history
bindkey '^[l' forward-char

bindkey '^P' up-history
bindkey '^N' down-history
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line

bindkey '^[b' backward-word
bindkey '^[f' forward-word

bindkey '^W' backward-kill-word
bindkey '^[d' kill-word
bindkey '^K' kill-line
bindkey '^U' backward-kill-line
bindkey '^[t' transpose-words

bindkey '^?' backward-delete-char
bindkey '^h' backward-delete-char

# Completions
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
  local command_name=$1 generated
  (( $+commands[$command_name] )) || return 0

  generated="$("$@" 2>/dev/null)" || return 0
  [[ $generated == \#compdef* ]] || return 0
  eval "$generated"
}

_load_generated_completion codex completion zsh
_load_generated_completion delta --generate-completion zsh
_load_generated_completion gh completion -s zsh
_load_generated_completion herdr completion zsh
_load_generated_completion mise completion zsh
_load_generated_completion pass-cli completions zsh
_load_generated_completion rg --generate=complete-zsh
_load_generated_completion rustup completions zsh
_load_generated_completion rv shell completions zsh
_load_generated_completion tailscale completion zsh
_load_generated_completion usage --completions zsh
_load_generated_completion uv generate-shell-completion zsh
_load_generated_completion uvx --generate-shell-completion zsh
_load_generated_completion zed --completions zsh

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

# fzf shell integration
if (( $+commands[fzf] )); then
  source <(fzf --zsh)
fi
