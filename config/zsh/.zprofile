# Configure readline
# export INPUTRC="${XDG_CONFIG_HOME}/readline/inputrc"

# =====================================
# Load profile modules
# =====================================

fpath=("${ZDOTDIR}"/functions $fpath)
autoload -Uz load_zsh_modules
load_zsh_modules "${ZDOTDIR}"/profile.d
