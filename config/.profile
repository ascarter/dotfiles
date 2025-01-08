export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-${HOME}/.config}
export DOTFILES=${DOTFILES:-${XDG_CONFIG_HOME}/dotfiles}

# Configure homebrew shell environment
if [ -d /opt/homebrew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# =======================================
# DEVELOPER
# =======================================

# Ruby
if command -v rbenv > /dev/null 2>&1 ; then
  eval "$(rbenv init -)"
fi

# Go
if command -v go > /dev/null 2>&1 ; then
  PATH=$(go env GOPATH)/bin:$PATH
fi

# Rust
if [ -d ${HOME}/.cargo ] ; then
  source ${HOME}/.cargo/env
fi

# Playdate
if [ -d ${HOME}/Developer/PlaydateSDK ] ; then
  export PLAYDATE_SDK_PATH=${HOME}/Developer/PlaydateSDK
  PATH="${PLAYDATE_SDK_PATH}"/bin:$PATH
fi

# Enable 1Password SSH agent if installed when running locally
if [ -z $SSH_TTY ] && [ -S ${HOME}/.1password/agent.sock ]; then
  export SSH_AUTH_SOCK=${HOME}/.1password/agent.sock
fi

# 1Password plugins
if [ -f ${XDG_CONFIG_HOME}/op/plugins.sh ]; then
  source ${XDG_CONFIG_HOME}/op/plugins.sh
fi

# Source bashrc if running in bash
if [ -n "$BASH_VERSION" ] ; then
  # include .bashrc if it exists
  if [ -f ${HOME}/.bashrc ] ; then
    source ${HOME}/.bashrc
  fi
fi

# Extra bin directories
bindirs=(
  ${HOME}/.local/bin
  ${HOME}/bin
  ${DOTFILES}/bin
)
for bindir in "${bindirs[@]}" ; do
  if [ -d "${bindir}" ] ; then
    PATH="${bindir}":$PATH
  fi
done
