# Configure homebrew shell environment
if [ -d /opt/homebrew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
  export HOMEBREW_NO_EMOJI=1
  brew analytics off
  fpath+=($HOMEBREW_PREFIX/share/zsh/site-functions $HOMEBREW_PREFIX/share/zsh-completions)
fi

# Go
if (( $+commands[go] )); then
  path+=$(go env GOPATH)/bin
fi
