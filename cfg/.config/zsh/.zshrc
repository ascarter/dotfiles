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
# Prompt
# =====================================

# Default: PS1="%m%# "
# Default macOS: PS1="%n@%m %1~ %#"
# Default Fedora: PS1="[%n@%m]%~%#"
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

setopt autocd extendedglob nomatch

# Change cursor shape according to vi mode
# Don't run when in Ghostty since it already supports this.
if [[ "$TERM" != *ghostty* && "$GHOSTTY_SHELL_INTEGRATION_NO_CURSOR" != 1 ]]; then
  # Change the cursor shape according to the current vi mode.
  _vi_zle_line_init _vi_zle_line_finish _vi_zle_keymap_select() {
    case ${KEYMAP-} in
      vicmd|visual)  print -Pn "\e[1 q" ;;
      *)             print -Pn "\e[5 q" ;;
    esac
  }

  # Bind the function to the ZLE hooks.
  zle -N zle-line-init     _vi_zle_line_init
  zle -N zle-line-finish   _vi_zle_line_finish
  zle -N zle-keymap-select _vi_zle_keymap_select

  # Before executing an external command, reset the cursor to its default shape.
  _vi_preexec_reset_cursor() {
    print -Pn "\e[0 q"
  }
  preexec_functions+=( _vi_preexec_reset_cursor )
fi

# Enable vim mode
bindkey -v

# =====================================
# Common shell configuration
# =====================================

if [[ -f ${HOME}/.shellrc ]]; then
  source ${HOME}/.shellrc
fi

# =====================================
# Per-machine extras
# =====================================

if [[ -e ${HOME}/.zsh_local ]]; then
  source ${HOME}/.zsh_local
fi
