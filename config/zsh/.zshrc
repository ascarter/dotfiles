# Non-interactive shell configuration:
# zshenv ➜ zprofile
#
# Interactive shell configuration:
# zshenv ➜ zprofile ➜ zshrc ➜ zlogin ➜ zlogout

# =====================================
# Completion system
# =====================================

# Add dev completions directory
if [[ -d "${XDG_DATA_HOME}/zsh/completions" ]]; then
  fpath=("${XDG_DATA_HOME}/zsh/completions" $fpath)
fi

# Enable advanced tab completion
autoload -Uz compinit
compinit -d "${XDG_CACHE_HOME}/zsh/zcompdump-${HOST}-${ZSH_VERSION}"

# Load colors
autoload -Uz colors
colors

# Load hook system
autoload -Uz add-zsh-hook

# Enable bash compatibility
autoload -Uz bashcompinit
bashcompinit
