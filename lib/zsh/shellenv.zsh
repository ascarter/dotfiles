# XDG defaults
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_BIN_HOME="${XDG_BIN_HOME:-$HOME/.local/bin}"

# dotfiles paths
export DOTFILES_HOME="$XDG_DATA_HOME/dotfiles"
export DOTFILES_TOOLS_HOME="$XDG_DATA_HOME/tools"]

# Zsh placement: config in XDG; state/cache outside the repo
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
export HISTFILE="$XDG_STATE_HOME/zsh/history"
export SHELL_SESSION_DIR="$XDG_STATE_HOME/zsh/sessions"

# Required dirs
[ -d "$ZDOTDIR" ] || mkdir -p "$ZDOTDIR"
[ -d "$XDG_STATE_HOME/zsh" ] || mkdir -p "$XDG_STATE_HOME/zsh"
[ -d "$XDG_CACHE_HOME/zsh" ] || mkdir -p "$XDG_CACHE_HOME/zsh"

# PATH management with de-dup
_dedup_prepend() { case ":$PATH:" in *":$1:"*) ;; *) PATH="$1${PATH:+:$PATH}" ;; esac }
_dedup_prepend "$DOTFILES_HOME/bin"
_dedup_prepend "$DOTFILES_TOOLS_HOME/bin"
_dedup_prepend "$XDG_BIN_HOME"
export PATH
