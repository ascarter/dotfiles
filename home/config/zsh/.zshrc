# zsh interactive shell configuration
#
# Config order (system wide then user):
# zshenv ➜ zprofile ➜ zshrc ➜ zlogin ➜ zlogout

# =====================================
# zsh
# =====================================

fpath+=(${ZDOTDIR}/functions ${ZDOTDIR}/prompts ${ZDOTDIR}/completions)

# Add local zsh functions
if [[ -d "${HOME}/.local/share/zsh/functions" ]]; then
  fpath+=(${HOME}/.local/share/zsh/functions)
fi

autoload -Uz compinit
compinit -u

autoload -U promptinit
promptinit

autoload -U colors
colors

autoload -U ${ZDOTDIR}/functions/[^_]*(:t)
autoload add-zsh-hook

# Support bash completions
autoload bashcompinit
bashcompinit

# Enable completion for aliases
setopt completealiases

# Completion configuration
zstyle ':completion:*' use-cache on
zstyle ':completion:*' completer _extensions _complete _approximate
zstyle ':completion:*' menu select
zstyle ':completion:*:*:*:*:descriptions' format '%F{green}-- %d --%f'
zstyle ':completion:*:*:*:*:corrections' format '%F{yellow}!- %d (errors: %e) -!%f'
zstyle ':completion:*:messages' format ' %F{purple} -- %d --%f'
zstyle ':completion:*:warnings' format ' %F{red}-- no matches found --%f'
zstyle ':completion:*' group-name ''
zstyle ':completion:*:*:-command-:*:*' group-order alias builtins functions commands
zstyle ':completion:*' file-list all
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

# =====================================
# Prompt
# =====================================

# Default: PS1="%m%# "
declare +x PS1
prompt dev

# =====================================
# Shell preferences
# =====================================

# Retain history across multiple zsh sessions
HISTFILE=${ZDOTDIR:-$HOME}/.zsh_history
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_REDUCE_BLANKS
SAVEHIST=5000
HISTSIZE=2000

# =====================================
# Key mappings
# =====================================

# Emacs key mappings
bindkey -e

# Forward delete
bindkey "^[[3~" delete-char

# fzf key bindings
if (( $+commands[fzf] )); then
  if [[ -d ${HOMEBREW_PREFIX}/opt/fzf ]]; then
    source "/opt/homebrew/opt/fzf/shell/completion.zsh"
    source "/opt/homebrew/opt/fzf/shell/key-bindings.zsh"
  fi
fi

# =====================================
# Editor
# =====================================

if (( $+commands[mg] )); then
  export EDITOR="mg"
elif (( $+commands[emacs] )); then
  export EDITOR="emacs -nw"
elif (( $+commands[nano] )); then
  export EDITOR="nano"
fi

if (( $+commands[nova] )); then
  export VISUAL="nova --wait"
elif (( $+commands[bbedit] )); then
  export VISUAL="bbedit --wait --resume --new-window"
elif (( $+commands[code] )); then
  export VISUAL="code --wait"
fi

# less
export LESS="--status-column --long-prompt --chop-long-lines --line-numbers --ignore-case --quit-if-one-screen -R"

# terminal theme
ttheme nova

# =====================================
# Aliases
# =====================================

if [[ -f ${ZDOTDIR}/aliases.zsh ]]; then
  source ${ZDOTDIR}/aliases.zsh
fi

# =====================================
# Per-machine extras
# =====================================

# Add local bin dir
if [[ -d ${HOME}/.local/bin ]]; then
    path+=${HOME}/.local/bin
fi

if [[ -e ${HOME}/.zsh_local ]]; then
  source ${HOME}/.zsh_local
fi
