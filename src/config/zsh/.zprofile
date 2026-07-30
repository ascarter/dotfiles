# Public login-shell configuration.

fpath=(
  "$ZDOTDIR/functions"
  "${XDG_DATA_HOME}/zsh/site-functions"
  $fpath
)

autoload -Uz load_zsh_modules
load_zsh_modules "$ZDOTDIR/profile.d"

# Root-level zsh files remain local and untracked. Load local login settings
# after public defaults so the local file may override them.
[[ -r "$HOME/.zprofile" ]] && source "$HOME/.zprofile"

