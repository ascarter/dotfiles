# If not running interactively, don't do anything
case $- in
    *i*) ;;
    *) return ;;
esac

# =====================================
# Shell options
# =====================================
HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s histappend
shopt -s checkwinsize
set -o vi

# =====================================
# Enable programmable completion
# =====================================
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# =====================================
# Prompt configuration
# =====================================
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

  for arg in "$@"; do
    case "$arg" in
      -nocolor) nocolor=1 ;;
      -twoline) twoline=1 ;;
    esac
  done

  if [[ "$TERM" == "xterm-256color" || "$TERM" == "screen-256color" || "$TERM" == "xterm-ghostty" ]]; then
    SEPARATOR=' ➜ '
    TRUNC_CHAR='…'
  else
    SEPARATOR=' | '
    TRUNC_CHAR='...'
    nocolor=1
  fi

  PS1=""
  if [[ -n $twoline ]]; then PS1+="\n"; fi
  if [[ -n $SSH_TTY ]]; then PS1+=$(__bash_prompt_color '\u@\h'"${SEPARATOR}" "34"); fi
  PS1+=$(__bash_prompt_color '\[\033[1m\]\w\[\033[0m\]' "34")
  if [[ -n $twoline ]]; then PS1+="\n"; else PS1+=" "; fi
  PS1+="\$ "
}

__bash_prompt
export PROMPT_DIRTRIM=4

# =====================================
# Include shared shell configuration
# =====================================
if [ -f ${HOME}/.shellrc ]; then
  source ${HOME}/.shellrc
fi

# =====================================
# Local configuration
# =====================================
if [ -f "${HOME}/.bash_local" ]; then
  source "${HOME}/.bash_local"
fi
