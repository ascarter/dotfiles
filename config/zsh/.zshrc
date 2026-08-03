# Public interactive-shell configuration.

typeset -g DOTFILES_HOME="${DOTFILES_HOME:-$HOME/Developer/dotfiles}"

fpath=(
  "$ZDOTDIR/functions"
  "${XDG_DATA_HOME}/zsh/site-functions"
  $fpath
)

# Homebrew publishes completions here on macOS.
if [[ -n ${HOMEBREW_PREFIX:-} && -d "$HOMEBREW_PREFIX/share/zsh/site-functions" ]]; then
  fpath=("$HOMEBREW_PREFIX/share/zsh/site-functions" $fpath)
fi

autoload -Uz load_zsh_modules

# Autoload public functions. A local ~/.zshrc can add more functions later.
for function_file in "$ZDOTDIR"/functions/*(-.N); do
  autoload -Uz "${function_file:t}"
done

# Navigation and completion behavior.
setopt \
  ALWAYS_TO_END \
  AUTO_CD \
  AUTO_PUSHD \
  COMPLETE_ALIASES \
  COMPLETE_IN_WORD \
  EXTENDED_GLOB \
  GLOB_DOTS \
  PUSHD_IGNORE_DUPS \
  PUSHD_SILENT \
  RM_STAR_WAIT

# History is persistent user state, not configuration.
mkdir -p "$XDG_STATE_HOME/zsh" "$XDG_CACHE_HOME/zsh"
HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=10000
SAVEHIST=10000
setopt \
  APPEND_HISTORY \
  HIST_EXPIRE_DUPS_FIRST \
  HIST_FIND_NO_DUPS \
  HIST_IGNORE_ALL_DUPS \
  HIST_IGNORE_DUPS \
  HIST_REDUCE_BLANKS \
  HIST_VERIFY \
  SHARE_HISTORY

# Prompt.
autoload -Uz promptinit
promptinit
prompt source

# Completion.
autoload -Uz compinit
compinit -d "$XDG_CACHE_HOME/zsh/zcompdump-${HOST}-${ZSH_VERSION}"

# Activate mise before public modules so globally managed commands are
# available to completion, editor, and other conditional integrations.
if (( $+commands[mise] )); then
  eval "$(mise activate zsh)"
fi

# Public modules load in lexical order.
load_zsh_modules "$ZDOTDIR/interactive.d"

# Root-level zsh files remain local and untracked. Load local interactive
# settings after public modules so aliases and preferences can be overridden.
[[ -r "$HOME/.zshrc" ]] && source "$HOME/.zshrc"
