# Configure homebrew shell environment
if [ -d /opt/homebrew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
  export HOMEBREW_NO_EMOJI=1
  export HOMEBREW_NO_ANALYTICS=1
  fpath+=($HOMEBREW_PREFIX/share/zsh/site-functions $HOMEBREW_PREFIX/share/zsh-completions)
fi

# ========================================
# Developer Tools
# ========================================

# Ruby
if (( $+commands[brew] )); then
  CHRUBY_PREFIX="${HOMEBREW_PREFIX}/opt/chruby"
else
  CHRUBY_PREFIX=/usr/local
fi

if [ -d "${CHRUBY_PREFIX}/share/chruby" ]; then
  source "${CHRUBY_PREFIX}/share/chruby/chruby.sh"
  source "${CHRUBY_PREFIX}/share/chruby/auto.sh"
fi

# Add Ruby 3.2.2 to MANPATH until I can patch chruby...
if [ -d "$HOME/.rubies/ruby-3.2.2/share/man" ]; then
  export MANPATH=$HOME/.rubies/ruby-3.2.2/share/man:$MANPATH
fi

# Node.JS
if (( $+commands[brew] )); then
  CHNODE_PREFIX="${HOMEBREW_PREFIX}/opt/chnode"
else
  CHNODE_PREFIX=/usr/local
fi

if [ -d "${CHNODE_PREFIX}/share/chnode" ]; then
  source "${CHNODE_PREFIX}/share/chnode/chnode.sh"
  source "${CHNODE_PREFIX}/share/chnode/auto.sh"
fi

# Python
if [ -d /Library/Frameworks/Python.framework ]; then
  path+=/Library/Frameworks/Python.framework/Versions/Current/bin
fi

# User pip installed binaries are in ~/Library
local pyver=$(python3 -c "import sys; print ('{}.{}'.format(sys.version_info.major, sys.version_info.minor))")
if [ -d ${HOME}/Library/Python/${pyver} ]; then
  export LC_ALL=en_US.UTF-8
  export LANG=en_US.UTF-8
  path+=${HOME}/Library/Python/${pyver}/bin
fi

# Go
if (( $+commands[go] )); then
  path+=$(go env GOPATH)/bin
fi

# Rust
if [ -d "${HOME}/.cargo" ]; then
  . "$HOME/.cargo/env"
fi

# Android
if [[ -d ${HOME}/Library/Android/sdk ]]; then
  export ANDROID_HOME=${HOME}/Library/Android/sdk
  path+=(${ANDROID_HOME}/tools ${ANDROID_HOME}/tools/bin ${ANDROID_HOME}/platform-tools)
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
