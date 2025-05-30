if [ -n "$BASH_VERSION" ]; then
  # Defaults:
  #   macOS:  PS1='\h:\W \u\$ '
  #   Fedora: PS1="[\u@\h \W]\\$ "
  #   Ubuntu: PS1='\u@\h:\w\$ '

  # Define text formatting escape sequences
  BOLD="\[\033[1m\]"
  DIM="\[\033[2m\]"
  ITALIC="\[\033[3m\]"
  RESET="\[\033[0m\]"

  GIT_BRANCH=""

  update_git_branch() {
    GIT_BRANCH=""
    if git rev-parse --git-dir >/dev/null 2>&1; then
      local branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD)
      if [ -n "$branch" ]; then
        GIT_BRANCH="$branch"
      fi
    fi
  }

  PROMPT_COMMAND="update_git_branch"

  PS1="${DIM}\u@\h${RESET}:${BOLD}\W${RESET}${DIM}${ITALIC}\${GIT_BRANCH:+ (\$GIT_BRANCH)}${RESET} \$ "

  # Add working directory to title if not using Ghostty
  if ! [ "$TERM" == "xterm-ghostty" ]; then
    PS1=${PS1}'\[\e]2;\w\a\]'
  fi
elif [ -n "$ZSH_VERSION" ]; then
  # Defauls:
  #   macOS:  PS1="%n@%m %1~ %#"
  #   Fedora: PS1="[%n@%m]%~%#"
  #   Ubuntu: PS1="%m%#"

  prompt_opts=(cr percent subst)
  autoload -Uz vcs_info
  autoload -Uz add-zsh-hook
  add-zsh-hook precmd vcs_info
  zstyle ':vcs_info:git:*' formats '%b'
  zstyle ':vcs_info:*' enable git
  zstyle ':vcs_info:*' check-for-changes false
  setopt prompt_subst

  DIM_ON="%{$(echo -e '\e[2m')%}"
  DIM_OFF="%{$(echo -e '\e[22m')%}"
  ITALIC_ON="%{$(echo -e '\e[3m')%}"
  ITALIC_OFF="%{$(echo -e '\e[23m')%}"

  PROMPT='${DIM_ON}%n@%m${DIM_OFF}:%B%1~%b${DIM_ON}${ITALIC_ON}${vcs_info_msg_0_:+ ($vcs_info_msg_0_)}${ITALIC_OFF}${DIM_OFF} %# '
fi

# Set grep colors on macOS
# Bold (1) and italic (3) with default foreground color (39)
export GREP_OPTIONS='--color=auto'
export GREP_COLOR='1;3;39'

# ls
# directories (di) bold (1)  default FG (39)
# symlink (ln)     italic(3) default FG (39)
# executable (ex)  dim (2)   default FG (39)
export LS_COLORS='di=1;39:ln=3;39:ex=2;39'

# vim: set ft=sh ts=2 sw=2 et:
