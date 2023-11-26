# Configure homebrew shell environment
if [ -d /opt/homebrew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
  export HOMEBREW_NO_EMOJI=1
  brew analytics off
  fpath+=($HOMEBREW_PREFIX/share/zsh/site-functions $HOMEBREW_PREFIX/share/zsh-completions)
fi

# ========================================
# Developer Tools
# ========================================

# chruby
if (( $+commands[brew] )); then
  CHRUBY_PREFIX="$(brew --prefix chruby)"
else
  CHRUBY_PREFIX=/usr/local
fi

if [ -d "$CHRUBY_PREFIX/share/chruby" ]; then
  source "${CHRUBY_PREFIX}/share/chruby/chruby.sh"
  source "${CHRUBY_PREFIX}/share/chruby/auto.sh"
fi

# Python
if [ -d /Library/Frameworks/Python.framework ]; then
  path+=/Library/Frameworks/Python.framework/Versions/Current/bin
fi

# User pip installed binaries are in ~/Library
local pyver=$(python3 -c "import sys; print ('{}.{}'.format(sys.version_info.major, sys.version_info.minor))")
if [[ -d ${HOME}/Library/Python/${pyver} ]]; then
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
