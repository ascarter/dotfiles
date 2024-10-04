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
# Locale
# =====================================
if [[ -z "${LANG}" ]]; then
  export LANG="en_US.UTF-8"
  export LC_COLLATE="en_US.UTF-8"
  export LC_CTYPE="en_US.UTF-8"
  export LC_MESSAGES="en_US.UTF-8"
  export LC_MONETARY="en_US.UTF-8"
  export LC_NUMERIC="en_US.UTF-8"
  export LC_TIME="en_US.UTF-8"
  export LC_ALL=
fi

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

  # Set CTRL+T defaults
  # p to toggle preview file content
  export FZF_CTRL_T_OPTS="
    --select-1 --exit-0
    --preview '(bat --color=always {} 2> /dev/null || cat {} || tree -C {}) 2> /dev/null | head -200'
    --preview-window 'hidden'
    --bind 'p:toggle-preview'"

  # Set CTRL+R defaults
  # CTRL-Y to copy the command into clipboard using pbcopy
  export FZF_CTRL_R_OPTS="
    --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
    --header 'Press CTRL-Y to copy command into clipboard'"

  # Print tree structure in the preview window
  export FZF_ALT_C_OPTS="--preview '(tree -C {}) 2> /dev/null | head -200'"
fi

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

# Use zed for visual editor or fallback to $EDITOR
if (( $+commands[zed] )); then
  export VISUAL="zed"
else
  export VISUAL=$EDITOR
fi

# less
export LESS="--status-column --long-prompt --chop-long-lines --line-numbers --ignore-case --quit-if-one-screen -R"

# ripgrep
export RIPGREP_CONFIG_PATH=${XDG_CONFIG_HOME}/ripgrep/config

# =====================================
# Browser
# =====================================

case $(uname) in
Darwin )
  export BROWSER="open -a Safari"
  ;;
Linux )
  # TODO - confirm already set in Linux
  # Fall back to lynx
  if [[ -z ${BROWSER} ]]; then
    export BROWSER=lynx
  fi
  ;;
esac

# =====================================
# Aliases
# =====================================

if [[ -f ${ZDOTDIR}/aliases.zsh ]]; then
  source ${ZDOTDIR}/aliases.zsh
fi

# =====================================
# SSH
# =====================================

# Use 1Password SSH agent if installed
if [[ -S ~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock ]]; then
    export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock
elif [[ -S ~/.1password/agent.sock ]]; then
    export SSH_AUTH_SOCK=~/.1password/agent.sock
fi

# =====================================
# Dotfiles
# =====================================

if [[ -d ${DOTFILES}/bin ]]; then
    path+=${DOTFILES}/bin
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
