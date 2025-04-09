# Set up dotfiles path
export DOTFILES=${DOTFILES:-${XDG_DATA_HOME}/dotfiles}
export PATH=${DOTFILES}/bin:$PATH
