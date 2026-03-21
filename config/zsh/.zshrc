# Non-interactive shell configuration:
# zshenv
#
# Interactive shell configuration:
# zshenv ➜ zprofile ➜ zshrc ➜ zlogin ➜ zlogout
#
# zprofile / zlogin / zlogout -- login shells only

# Minimal support when root
if [[ $EUID -eq 0 ]]; then
  PROMPT='%F{red}%n@%m%f %B%2~%b %F{red}%#%f '
  return 0
fi

# =====================================
# Functions
# =====================================

# Add functions directory to fpath
fpath=("${ZDOTDIR}/functions" $fpath)

# Autoload function definitions
if [[ -d ${ZDOTDIR}/functions ]]; then
  for f in "${ZDOTDIR}"/functions/*(-.N); do
    autoload -Uz "${f:t}"
  done
fi

# =====================================
# Prompt
# =====================================

autoload -Uz promptinit
promptinit
prompt source

# =====================================
# Options
# =====================================

setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT COMPLETE_ALIASES ALWAYS_TO_END COMPLETE_IN_WORD EXTENDED_GLOB GLOB_DOTS

# Ask for confirmation for `rm *' or `rm path/*'
setopt RM_STAR_WAIT

# Sessions
[[ -d ${XDG_STATE_HOME}/zsh/sessions ]] || mkdir -p "${XDG_STATE_HOME}"/zsh/sessions
SHELL_SESSION_DIR="${XDG_STATE_HOME}"/zsh/sessions
setopt SHARE_HISTORY

# History
HISTFILE="${XDG_STATE_HOME}"/zsh/history
HISTSIZE=10000
SAVEHIST=10000

setopt APPEND_HISTORY INC_APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS HIST_REDUCE_BLANKS HIST_VERIFY

# =====================================
# Completion system
# =====================================

# Add homebrew completions directory
if [[ -d $HOMEBREW_PREFIX/share/zsh/site-functions ]]; then
  fpath=($HOMEBREW_PREFIX/share/zsh/site-functions $fpath)
fi

# Add opt-managed tool completions directory
if [[ -d ${XDG_OPT_SHARE}/completions ]]; then
  fpath=("${XDG_OPT_SHARE}"/completions $fpath)
fi

# Add XDG completions directory
if [[ -d ${XDG_STATE_HOME}/zsh/completions ]]; then
  fpath=("${XDG_STATE_HOME}"/zsh/completions $fpath)
fi

# Enable advanced tab completion
[[ -d ${XDG_CACHE_HOME}/zsh ]] || mkdir -p "${XDG_CACHE_HOME}"/zsh
autoload -Uz compinit
compinit -d "${XDG_CACHE_HOME}/zsh/zcompdump-${HOST}-${ZSH_VERSION}"

# =====================================
# Load interactive modules
# =====================================

load_zsh_modules "${ZDOTDIR}"/interactive.d

# =====================================
# Final PATH assertion
# =====================================
# Re-prepend managed paths so they shadow system and brew binaries
# (profile.d and interactive.d modules may have prepended their own)
path=("$XDG_OPT_BIN" "$XDG_BIN_HOME" $path)
