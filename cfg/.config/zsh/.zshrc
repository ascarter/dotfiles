fpath+=(${ZDOTDIR}/functions ${ZDOTDIR}/prompts ${ZDOTDIR}/completions)

# Add Docker Desktop
if [[ -d ${HOME}/.docker ]]; then
  fpath+=(${HOME}/.docker/completions)
fi

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

if [[ -d ${ZDOTDIR}/functions ]]; then
  autoload -U ${ZDOTDIR}/functions/[^_]*(:t)
fi
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
zstyle ':completion:*' list-dirs-first true
zstyle ':completion:*' file-list all
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

# =====================================
# Prompt
# =====================================

# Default: PS1="%m%# "
# Default macOS: PS1="%n@%m %1~ %#"
declare +x PS1
prompt terminal

# =====================================
# Shell preferences
# =====================================

# Retain history across multiple zsh sessions
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_REDUCE_BLANKS

# =====================================
# Editor
# =====================================

# Use helix ➜ nano ➜ vi for editor
if (( $+commands[hx] )); then
  export EDITOR="hx"
elif (( $+commands[nano] )); then
  export EDITOR="nano"
else
  export EDITOR="vi"
fi

# =====================================
# Tools
# =====================================

# less
export LESS="--status-column --long-prompt --chop-long-lines --line-numbers --ignore-case --quit-if-one-screen -R"

# ripgrep
export RIPGREP_CONFIG_PATH=${XDG_CONFIG_HOME}/ripgrep/config

# tlrc
export TLRC_CONFIG=${XDG_CONFIG_HOME}/tlrc/config.toml

# =====================================
# Developer
# =====================================

# Rust
if [[ -d ${HOME}/.cargo ]]; then
  source "$HOME/.cargo/env"
fi

# =====================================
# SSH
# =====================================

# Enable 1Password SSH agent if installed when running locally
if [ -z $SSH_TTY ] && [ -S ${HOME}/.1password/agent.sock ]; then
  export SSH_AUTH_SOCK=${HOME}/.1password/agent.sock
fi

# 1Password plugins
if [ -f ${XDG_CONFIG_HOME}/op/plugins.sh ]; then
  source ${XDG_CONFIG_HOME}/op/plugins.sh
fi

# =====================================
# Aliases
# =====================================

if [[ -f ${HOME}/.aliases ]]; then
  source ${HOME}/.aliases
fi

# =====================================
# Per-machine extras
# =====================================

if [[ -e ${HOME}/.zsh_local ]]; then
  source ${HOME}/.zsh_local
fi
