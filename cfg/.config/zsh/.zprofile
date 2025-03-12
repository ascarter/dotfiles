export DOTFILES=${DOTFILES:-${XDG_DATA_HOME}/dotfiles}

# Configure homebrew
export HOMEBREW_NO_EMOJI=1
if [ -d /opt/homebrew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -d /home/linuxbrew/.linuxbrew ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
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

if (( $+commands[mise] )); then
  if [[ -o interactive ]]; then
    eval "$(mise activate zsh)"
  else
    eval "$(mise activate zsh --shims)"
  fi
fi
