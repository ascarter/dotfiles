# zsh interactive shell configuration
#
# Config order (system wide then user):
# zshenv ➜ zprofile ➜ zshrc ➜ zlogin ➜ zlogout

fpath+=(${ZDOTDIR}/functions ${ZDOTDIR}/prompts ${ZDOTDIR}/completions)

# Add local zsh functions
if [ -d "${HOME}/.local/share/zsh/functions" ]; then
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

# ===========
# Prompt
# ===========

# Default: PS1="%m%# "
declare +x PS1
prompt dev

# ========================================
# Shell preferences
# ========================================

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

# Key mappings

# Emacs key mappings
bindkey -e

# Forward delete
bindkey "^[[3~" delete-char

# Editor
export EDITOR="vim"
export VISUAL="vim -g"
if (( $+commands[bbedit] )); then
  export VISUAL="bbedit --wait --resume --new-window"
fi

export LESSEDIT='vim ?lm+%lm. %f'
export TEXEDIT='vim +%d %s'

# less
export PAGER="less -r"
export LESS="--status-column --long-prompt --no-init --quit-if-one-screen --quit-at-eof -R"

# terminal theme
ttheme panic

# ========================================
# Developer
# ========================================

# Kubernetes (microk8s)
if (( $+commands[microk8s.kubectl] )); then
  compdef microk8s.kubectl=kubectl
fi

# ========================================
# Aliases
# ========================================

if [ -f ${ZDOTDIR}/aliases.zsh ]; then
  source ${ZDOTDIR}/aliases.zsh
fi

# ========================================
# Path settings
# ========================================

# Add local bin dir
if [[ -d ${HOME}/.local/bin ]]; then
    path+=${HOME}/.local/bin
fi

# ========================================
# SSH
# ========================================

# Use 1Password SSH Agent if installed
if [ -S ${HOME}/.1password/agent.sock ]; then
  export SSH_AUTH_SOCK=${HOME}/.1password/agent.sock
elif [[ $(uname) == "Linux" ]]; then
  if [[ $(uname -r) == *Microsoft* ]]; then
    # WSL - use named pipe to Windows host ssh-agent
    if type npiperelay.exe &>/dev/null; then
      export SSH_AUTH_SOCK=${HOME}/.ssh/agent.sock
      ss -a | grep -q $SSH_AUTH_SOCK
      if [ $? -ne 0 ]; then
        rm -f ${SSH_AUTH_SOCK}
        ( setsid socat UNIX-LISTEN:${SSH_AUTH_SOCK},fork EXEC:"npiperelay.exe -ei -s //./pipe/openssh-ssh-agent",nofork & ) >/dev/null 2>&1
      fi
    fi
  fi
fi

# ========================================
# 1Password
# ========================================

if [ -f ${HOME}/.config/op/plugins.sh ]; then
  source ${HOME}/.config/op/plugins.sh
fi

# ========================================
# Per-machine extras
# ========================================
if [ -e ${HOME}/.zsh_local ]; then
    source ${HOME}/.zsh_local
fi
