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
# Load interactive modules
# =====================================

load_zsh_modules "${ZDOTDIR}"/interactive.d
