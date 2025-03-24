# Common profile configuration for both bash and zsh
# This file should be sourced from both .profile and .zprofile

export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
export XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
export DOTFILES=${DOTFILES:-${XDG_DATA_HOME}/dotfiles}

# Configure homebrew
export HOMEBREW_NO_EMOJI=1
if [ -d /opt/homebrew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -d /home/linuxbrew/.linuxbrew ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Extra bin directories
if [ -n "$ZSH_VERSION" ]; then
  # ZSH-specific implementation
  typeset -U path
  path=($DOTFILES/bin $HOME/bin $HOME/.local/bin $path)
else
  # POSIX sh/bash implementation
  for bindir in "${DOTFILES}/bin" "${HOME}/bin" "${HOME}/.local/bin"; do
    if [ -d "${bindir}" ]; then
      case ":${PATH}:" in
        *:"${bindir}":*) ;;
        *) PATH="${bindir}:${PATH}" ;;
      esac
    fi
  done
fi

# Source .bashrc for interactive bash shells
if [ -n "$BASH_VERSION" ] && [ -f "${HOME}/.bashrc" ]; then
  source "${HOME}/.bashrc"
fi
