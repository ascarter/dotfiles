# Set up dotfiles path
export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
export XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
export DOTFILES=${DOTFILES:-${XDG_DATA_HOME}/dotfiles}
export PATH=${DOTFILES}/bin:$PATH
