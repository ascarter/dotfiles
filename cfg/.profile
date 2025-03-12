export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
export XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
export DOTFILES=${DOTFILES:-${XDG_DATA_HOME}/dotfiles}

# Configure homebrew
if [ -d /opt/homebrew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Extra bin directories
bindirs=(
  ${DOTFILES}/bin
  ${HOME}/bin
  ${HOME}/.local/bin
)
for bindir in "${bindirs[@]}" ; do
  if [ -d "${bindir}" ] ; then
    PATH="${bindir}":$PATH
  fi
done

# Source .bashrc if it exists
if [ -f ${HOME}/.bashrc ] ; then
  source ${HOME}/.bashrc
fi
