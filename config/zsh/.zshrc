# Non-interactive shell configuration:
# zshenv
#
# Interactive shell configuration:
# zshenv ➜ zprofile ➜ zshrc ➜ zlogin ➜ zlogout
#
# zprofile / zlogin / zlogout -- login shells only

# =====================================
# Functions
# =====================================

# Add functions directory to fpath
fpath=("${ZDOTDIR}/functions" $fpath)

# Autoload function definitions
if [[ -d ${ZDOTDIR}/functions ]]; then
  for f in "${ZDOTDIR}/functions"/*(-.N); do
    autoload -Uz "${f:t}"
  done
fi

# Load colors
autoload -Uz colors
colors

# =====================================
# Prompt
# =====================================

autoload -Uz promptinit
promptinit
prompt git

# =====================================
# Options
# =====================================

setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT COMPLETE_ALIASES ALWAYS_TO_END COMPLETE_IN_WORD EXTENDED_GLOB GLOB_DOTS

# Ask for confirmation for `rm *' or `rm path/*'
setopt RM_STAR_WAIT

# Sessions
[[ -d ${XDG_STATE_HOME}/zsh/sessions ]] || mkdir -p "${XDG_STATE_HOME}/zsh/sessions"
SHELL_SESSION_DIR="${XDG_STATE_HOME}/zsh/sessions"
setopt SHARE_HISTORY

# History
HISTFILE="${XDG_STATE_HOME}/zsh/history"
HISTSIZE=10000
SAVEHIST=10000

setopt APPEND_HISTORY INC_APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS HIST_REDUCE_BLANKS HIST_VERIFY

# =====================================
# Completion configuration
# =====================================

# Add XDG completions directory
if [[ -d ${XDG_DATA_HOME}/zsh/completions ]]; then
  fpath=("${XDG_DATA_HOME}/zsh/completions" $fpath)
fi

# Enable advanced tab completion
[[ -d ${XDG_CACHE_HOME}/zsh ]] || mkdir -p "${XDG_CACHE_HOME}"/zsh
autoload -Uz compinit
compinit -d "${XDG_CACHE_HOME}/zsh/zcompdump-${HOST}-${ZSH_VERSION}"

# Automatically rehash command list when new executables are added
zstyle ':completion:*' rehash true

# Cache completion for performance
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"

# Completion behavior
zstyle ':completion:*' completer _extensions _complete _approximate
zstyle ':completion:*' menu select
zstyle ':completion:*:*:*:*:descriptions' format '%F{green}-- %d --%f'
zstyle ':completion:*:*:*:*:corrections' format '%F{yellow}!- %d (errors: %e) -!%f'
zstyle ':completion:*:messages' format ' %F{purple} -- %d --%f'
zstyle ':completion:*:warnings' format ' %F{red}-- no matches found --%f'
zstyle ':completion:*' group-name ''
zstyle ':completion:*:*:-command-:*:*' group-order alias builtins functions commands
zstyle ':completion:*' list-dirs-first true
zstyle ':completion:*' file-list all

# Fuzzy matching for completion
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# Enable bash compatibility
# autoload -Uz bashcompinit
# bashcompinit

# =====================================
# Key bindings (Emacs mode with Vim-inspired enhancements)
# =====================================

# Enable Emacs editing mode
bindkey -e

# Edit command line in $EDITOR (Helix/Zed)
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line        # Ctrl-X Ctrl-E to open current line in $EDITOR

# Vim-like movement on Meta-h/j/k/l (useful on HHKB without arrows)
bindkey '^[h' backward-char
bindkey '^[l' forward-char
bindkey '^[j' down-line-or-history
bindkey '^[k' up-line-or-history

# Explicit standard movements/history (some already default)
bindkey '^P' up-history
bindkey '^N' down-history
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line

# Word motions (Meta-b/f are default; declare for clarity)
bindkey '^[b' backward-word
bindkey '^[f' forward-word

# Deletions / kills
bindkey '^W' backward-kill-word         # kill previous word
bindkey '^[d' kill-word                 # Meta-d kill next word
bindkey '^K' kill-line                  # kill to end of line
bindkey '^U' backward-kill-line         # kill to start of line
bindkey '^[t' transpose-words           # swap adjacent words

# Backspace variations
bindkey '^?' backward-delete-char
bindkey '^h' backward-delete-char

# =====================================
# Load interactive modules
# =====================================

load_zsh_modules "${ZDOTDIR}/interactive.d"
