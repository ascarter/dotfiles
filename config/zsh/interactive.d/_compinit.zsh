# =====================================
# Completion configuration
# =====================================

# Add homebrew completions directory
if [[ -d $HOMEBREW_PREFIX/share/zsh/site-functions ]]; then
  fpath=($HOMEBREW_PREFIX/share/zsh/site-functions $fpath)
fi

# Add XDG completions directory
if [[ -d ${XDG_STATE_HOME}/zsh/completions ]]; then
  fpath=("${XDG_STATE_HOME}"/zsh/completions $fpath)
fi

# Enable advanced tab completion
[[ -d ${XDG_CACHE_HOME}/zsh ]] || mkdir -p "${XDG_CACHE_HOME}"/zsh
autoload -Uz compinit
compinit -d "${XDG_CACHE_HOME}/zsh/zcompdump-${HOST}-${ZSH_VERSION}"

# Automatically rehash command list when new executables are added
zstyle ':completion:*' rehash true

# Cache completion for performance
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}"/zsh/zcompcache

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
