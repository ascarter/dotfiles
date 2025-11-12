if ! (( $+commands[zed] )); then
  if (( $+commands[zed-preview] )); then
    alias zed=zed-preview
  fi
fi

if (( $+commands[zed] )); then
  alias dfedit="EDITOR=zed dev edit"
fi

alias dfcd='cd ${DOTFILES_HOME}'

if [[ -d ~/Developer ]]; then
  alias dev='cd ~/Developer'
fi

# ls - Use uutils if installed
if (( $+commands[uls] )); then
  alias ls='uls --group-directories-first --color=auto --human-readable'
  alias lc='ls -l -a --classify=auto'
fi
alias la='ls -a -l'
alias ll='ls -l'
alias l.='ls -d .*'

# ssh
alias sshpw="ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no"

# Developer tools

if (( $+commands[rustup] )); then
  alias rustbook="rustup doc --book"
fi

# Platform specific aliases
case $(uname) in
Darwin)
  # System information
  alias about="system_profiler SPHardwareDataType SPSoftwareDataType SPStorageDataType"
  alias sysver="sw_vers"

  # Rebuild Spotlight index
  alias spotlight-rebuild="sudo mdutil -E /"

  # De-quarantine
  alias dequarantine="xattr -d com.apple.quarantine"

  # QuickLook
  alias ql='qlmanage -p "$@" >& /dev/null'

  # Safari
  alias safari="open -a Safari"

  # Sketch
  alias sketchtool="$(mdfind kMDItemCFBundleIdentifier = 'com.bohemiancoding.sketch3' | head -n 1)/Contents/Resources/sketchtool/bin/sketchtool"

  # Tailscale
  if [[ -d /Applications/Tailscale.app ]]; then
    alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"
  fi

  # Proxyman
  if [[ -d /Applications/Proxyman.app ]]; then
    alias proxyman-cli="/Applications/Proxyman.app/Contents/MacOS/proxyman-cli"
  fi
  ;;
Linux)
  # Linux version of macOS pbcopy/pbpaste.
  if (( $+commands[xsel] )); then
    alias pbcopy="xsel --clipboard --input"
    alias pbpaste="xsel --clipboard --output"
  fi

  if (( $+commands[flatpak] )); then
    if flatpak info io.github.shiftey.Desktop &>/dev/null; then
      alias github='flatpak run io.github.shiftey.Desktop'
    fi
  fi
  ;;
esac
