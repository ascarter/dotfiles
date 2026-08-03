alias dotfiles-cd='cd "$DOTFILES_HOME"'
alias dotfiles-update='mise -C "$DOTFILES_HOME" run update'
if (( $+commands[zed] )); then
  alias dotfiles-edit='zed "$DOTFILES_HOME"'
fi

alias bbcurl='edcurl -e bbedit'
alias nvcurl='edcurl -e nvim'
alias zcurl='edcurl -e zed'

[[ -d "$HOME/Developer" ]] && alias dev='cd "$HOME/Developer"'

if (( $+commands[uu-ls] )); then
  alias ls='uu-ls --group-directories-first --color=auto --human-readable'
fi

alias la='ls -a -l'
alias ll='ls -l'
alias l.='ls -d .*'
alias sshpw='ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no'

if (( $+commands[btm] )); then
  alias htop='btm --basic'
fi

case "$(uname)" in
  Darwin)
    alias about='system_profiler SPHardwareDataType SPSoftwareDataType SPStorageDataType'
    alias dequarantine='xattr -d com.apple.quarantine'
    alias spotlight-rebuild='sudo mdutil -E /'
    alias sysver='sw_vers'

    if (( ! $+commands[tailscale] )) && [[ -x /Applications/Tailscale.app/Contents/MacOS/Tailscale ]]; then
      alias tailscale='/Applications/Tailscale.app/Contents/MacOS/Tailscale'
    fi

    if [[ -x "/Applications/Proton Mail Bridge.app/Contents/MacOS/Proton Mail Bridge" ]]; then
      alias protonmail-bridge='"/Applications/Proton Mail Bridge.app/Contents/MacOS/Proton Mail Bridge"'
    fi
    ;;
  Linux)
    if (( $+commands[xsel] )); then
      alias pbcopy='xsel --clipboard --input'
      alias pbpaste='xsel --clipboard --output'
    fi
    ;;
esac
