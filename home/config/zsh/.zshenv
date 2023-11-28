# zsh env configuration
#
# Config order (system wide then user):
# zshenv ➜ zprofile ➜ zshrc ➜ zlogin ➜ zlogout

# =====================================
# DOTFILES
# =====================================

export DOTFILES=${DOTFILES:=${XDG_CONFIG_HOME:=$HOME/.config}/dotfiles}

# =====================================
# Homebrew
# =====================================

# Configure homebrew shell environment
if [[ -d /opt/homebrew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
  export HOMEBREW_NO_EMOJI=1
  export HOMEBREW_NO_ANALYTICS=1
  fpath+=($HOMEBREW_PREFIX/share/zsh/site-functions $HOMEBREW_PREFIX/share/zsh-completions)
fi

# =====================================
# Developer
# =====================================

# Ruby
if (( $+commands[brew] )); then
  CHRUBY_PREFIX="${HOMEBREW_PREFIX}/opt/chruby"
else
  CHRUBY_PREFIX=/usr/local
fi

if [[ -d "${CHRUBY_PREFIX}/share/chruby" ]]; then
  source "${CHRUBY_PREFIX}/share/chruby/chruby.sh"
  source "${CHRUBY_PREFIX}/share/chruby/auto.sh"
fi

# Add Ruby 3.2.2 to MANPATH until I can patch chruby...
if [[ -d "$HOME/.rubies/ruby-3.2.2/share/man" ]]; then
  export MANPATH=$HOME/.rubies/ruby-3.2.2/share/man:$MANPATH
fi

# Node.JS
if (( $+commands[brew] )); then
  CHNODE_PREFIX="${HOMEBREW_PREFIX}/opt/chnode"
else
  CHNODE_PREFIX=/usr/local
fi

if [[ -d "${CHNODE_PREFIX}/share/chnode" ]]; then
  source "${CHNODE_PREFIX}/share/chnode/chnode.sh"
  source "${CHNODE_PREFIX}/share/chnode/auto.sh"
fi

# Go
if (( $+commands[go] )); then
  path+=$(go env GOPATH)/bin
fi

# Rust
if [[ -d "${HOME}/.cargo" ]]; then
  . "$HOME/.cargo/env"
fi

# ========================================
# 1Password
# ========================================

if [ -f ${HOME}/.config/op/plugins.sh ]; then
  source ${HOME}/.config/op/plugins.sh
fi

# =====================================
# SSH
# =====================================

# Use 1Password SSH Agent if installed
if [[ -S ${HOME}/.1password/agent.sock ]]; then
  export SSH_AUTH_SOCK=${HOME}/.1password/agent.sock
fi
