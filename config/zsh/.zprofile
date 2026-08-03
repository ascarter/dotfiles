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

# Make mise-managed tools available to login shells. Interactive shells replace
# this with full PATH activation in .zshrc while retaining shims as a fallback.
if (( $+commands[mise] )); then
  eval "$(mise activate zsh --shims)"
fi
