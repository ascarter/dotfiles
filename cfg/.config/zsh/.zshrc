# =====================================
# Path and function loading
# =====================================

# Add function directories to fpath
typeset -U fpath
fpath=(${ZDOTDIR}/functions ${ZDOTDIR}/prompts ${ZDOTDIR}/completions $fpath)

# Add local zsh functions
if [[ -d "${HOME}/.local/share/zsh/functions" ]]; then
  fpath=(${HOME}/.local/share/zsh/functions $fpath)
fi

# =====================================
# Completion system
# =====================================

# Enable advanced tab completion
autoload -Uz compinit
compinit -u

# Load colors
autoload -Uz colors
colors

# Enable prompts
autoload -U promptinit
promptinit

# Load utility functions, ignoring those starting with underscore
if [[ -d ${ZDOTDIR}/functions ]]; then
  autoload -Uz ${ZDOTDIR}/functions/[^_]*(:t)
fi

# Load hook system
autoload -Uz add-zsh-hook

# Enable bash compatibility
autoload -Uz bashcompinit
bashcompinit

# =====================================
# ZSH Options
# =====================================

# Changing directories
setopt AUTO_PUSHD             # Push the old directory onto the stack on cd
setopt PUSHD_IGNORE_DUPS      # Do not store duplicates in the stack
setopt PUSHD_SILENT           # Do not print directory stack after pushd/popd

# Completion
setopt COMPLETE_ALIASES       # Enable completion for aliases
setopt ALWAYS_TO_END          # Move cursor to end of word on completion
setopt COMPLETE_IN_WORD       # Allow completion from middle of word

# Expansion and globbing
setopt EXTENDED_GLOB          # Use extended globbing syntax
setopt GLOB_DOTS              # Include hidden files in globbing

# History
setopt SHARE_HISTORY          # Share history between sessions
setopt APPEND_HISTORY         # Append to history file
setopt HIST_EXPIRE_DUPS_FIRST # Delete duplicates first when trimming history
setopt HIST_IGNORE_DUPS       # Don't record if same as previous command
setopt HIST_FIND_NO_DUPS      # Don't display duplicates when searching
setopt HIST_REDUCE_BLANKS     # Remove superfluous blanks from commands
setopt HIST_VERIFY            # Show command before executing history command

# Input/Output
setopt RM_STAR_WAIT            # Ask for confirmation for `rm *' or `rm path/*'

# =====================================
# Completion configuration
# =====================================

# Cache completion for performance
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"

# Completion behavior
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

# Fuzzy matching for completion
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# =====================================
# Prompt
# =====================================

# Default: PS1="%m%# "
# Default macOS:  PS1="%n@%m %1~ %#"
# Default Fedora: PS1="[%n@%m]%~%#"
# Default Ubuntu: PS1="%m%#"
# unset PS1
prompt terminal
# PS1="[%n@%m]%1~ %# "

# =====================================
# Key bindings & Vi Mode
# =====================================

# Enable vim mode
bindkey -v

# Better vim mode experience
export KEYTIMEOUT=1  # Reduce delay when switching modes

# Change cursor shape according to vi mode
# Don't run when in Ghostty since it already supports this.
if [[ "$TERM" != *ghostty* && "$GHOSTTY_SHELL_INTEGRATION_NO_CURSOR" != 1 ]]; then
  # Change the cursor shape according to the current vi mode.
  _vi_cursor_mode() {
    case ${KEYMAP-} in
      vicmd|visual)  print -Pn "\e[1 q" ;;  # Block cursor
      *)             print -Pn "\e[5 q" ;;  # Beam cursor
    esac
  }

  # Bind cursor mode function to appropriate ZLE hooks
  zle-line-init() { _vi_cursor_mode }
  zle-keymap-select() { _vi_cursor_mode }

  # Register functions as ZLE widgets
  zle -N zle-line-init
  zle -N zle-keymap-select

  # Reset cursor before executing commands
  _vi_preexec_reset_cursor() {
    print -Pn "\e[0 q"
  }
  add-zsh-hook preexec _vi_preexec_reset_cursor
fi

# Add useful vi-mode key bindings
bindkey '^P' up-history
bindkey '^N' down-history
bindkey '^?' backward-delete-char
bindkey '^h' backward-delete-char
bindkey '^w' backward-kill-word

# =====================================
# Shell configuration
# =====================================

# Set up dotfiles path
export DOTFILES=${DOTFILES:-${XDG_DATA_HOME}/dotfiles}
path=($DOTFILES/bin $HOME/.local/bin $path)

# Homebrew configuration
export HOMEBREW_NO_EMOJI=1
if [[ -d /opt/homebrew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -d /home/linuxbrew/.linuxbrew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Ruby configuration
if (( $+commands[rbenv] )); then
  eval "$(rbenv init - zsh)"
fi

# Rust configuration
if [[ -d ${HOME}/.cargo ]]; then
  source "$HOME/.cargo/env"
fi

# Editor preference
if (( $+commands[nvim] )); then
  export EDITOR="nvim"
elif (( $+commands[vim] )); then
  export EDITOR="vim"
else
  export EDITOR="vi"
fi

# less
export LESS="--status-column --long-prompt --chop-long-lines --line-numbers --ignore-case --quit-if-one-screen -R"

# ripgrep
export RIPGREP_CONFIG_PATH=${XDG_CONFIG_HOME}/ripgrep/config

# tlrc
export TLRC_CONFIG=${XDG_CONFIG_HOME}/tlrc/config.toml

# =====================================
# SSH Configuration
# =====================================

# Enable 1Password SSH agent if installed when running locally
if [ -z "$SSH_TTY" ] && [ -S "${HOME}/.1password/agent.sock" ]; then
  export SSH_AUTH_SOCK="${HOME}/.1password/agent.sock"
fi

# 1Password plugins
if [ -f "${XDG_CONFIG_HOME}/op/plugins.sh" ]; then
  source "${XDG_CONFIG_HOME}/op/plugins.sh"
fi
