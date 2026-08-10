# Login shell configuration.

fpath=(
  "$ZDOTDIR/functions"
  $fpath
)

# Shell integration for mise's partial Homebrew prefix.
if [[ -d /opt/homebrew ]]; then
  export HOMEBREW_PREFIX=/opt/homebrew
  export HOMEBREW_CELLAR=/opt/homebrew/Cellar
  export HOMEBREW_REPOSITORY=/opt/homebrew

  typeset -U path
  path=(/opt/homebrew/bin /opt/homebrew/sbin $path)

  export MANPATH="/opt/homebrew/share/man${MANPATH:+:$MANPATH}:"

  if [[ -d /opt/homebrew/share/info ]]; then
    export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}"
  fi
fi

# Root-level zsh files remain local and untracked.
# mise activation happens in local .zprofile
[[ -r "$HOME/.zprofile" ]] && source "$HOME/.zprofile"
