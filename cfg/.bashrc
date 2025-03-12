# If not running interactively, don't do anything
case $- in
    *i*)
        ;;
      *)
        # if command -v mise &> /dev/null; then
        #   eval "$(mise activate bash --shims)"
        # fi
        return
        ;;
esac

# Enable mise
if command -v mise > /dev/null 2>&1 ; then
  eval "$(mise activate bash)"
fi

# Rust
if [[ -d ${HOME}/.cargo ]]; then
  source "$HOME/.cargo/env"
fi

# Set tlrc config
export TLRC_CONFIG=${XDG_CONFIG_HOME}/tlrc/config.toml

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
#[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# Use helix ➜ nano ➜ vi for editor
if command -v hx > /dev/null 2>&1 ; then
  export EDITOR="hx"
elif command -v nano > /dev/null 2>&1 ; then
  export EDITOR="nano"
else
  export EDITOR="vi"
fi

# less
export LESS="--status-column --long-prompt --chop-long-lines --line-numbers --ignore-case --quit-if-one-screen -R"

# ripgrep
export RIPGREP_CONFIG_PATH=${XDG_CONFIG_HOME}/ripgrep/config

# Enable 1Password SSH agent if installed when running locally
if [ -z $SSH_TTY ] && [ -S ${HOME}/.1password/agent.sock ]; then
  export SSH_AUTH_SOCK=${HOME}/.1password/agent.sock
fi

# 1Password plugins
if [ -f ${XDG_CONFIG_HOME}/op/plugins.sh ]; then
  source ${XDG_CONFIG_HOME}/op/plugins.sh
fi

# Alias definitions.
if [ -f ~/.aliases ]; then
    . ~/.aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# Function to add colors (fallback to no color if $nocolor is set)
__bash_prompt_color() {
  if [ -z "${nocolor}" ]; then
    echo -e "\[\033[$2m\]$1\[\033[0m\]"
  else
    echo -n "$1"
  fi
}

__bash_prompt() {
  local nocolor=""
  local twoline=""

  # Check for options (simulating zparseopts)
  for arg in "$@"; do
    case "$arg" in
      -nocolor) nocolor=1 ;;
      -twoline) twoline=1 ;;
    esac
  done

  # Determine terminal type
  if [[ "$TERM" == "xterm-256color" || "$TERM" == "screen-256color" || "xterm-ghostty" ]]; then
    SEPARATOR=' ➜ '
    TRUNC_CHAR='…'
  else
    SEPARATOR=' | '
    TRUNC_CHAR='...'
    nocolor=1
  fi

  # Construct the PS1 variable
  PS1=""

  # Add newline if using two-line prompt
  if [[ -n $twoline ]]; then
    PS1+="\n"
  fi

  # user@host (shown only for SSH sessions)
  if [[ -n $SSH_TTY ]]; then
    PS1+=$(__bash_prompt_color '\u@\h'"${SEPARATOR}" "34")
  fi

  # Current directory, truncated
  PS1+=$(__bash_prompt_color '\[\033[1m\]\w\[\033[0m\]' "34")

  # Add newline for two-line prompt
  if [[ -n $twoline ]]; then
    PS1+="\n"
  else
    PS1+=" "
  fi

  # Input prompt symbol
  PS1+="\$ "

  # Apply the prompt
  export PS1
}

# Initialize the prompt
__bash_prompt
export PROMPT_DIRTRIM=4
