# Login shell configuration.

fpath=(
  "$ZDOTDIR/functions"
  $fpath
)

# Root-level zsh files remain local and untracked.
# mise activation happens in local .zprofile
[[ -r "$HOME/.zprofile" ]] && source "$HOME/.zprofile"
