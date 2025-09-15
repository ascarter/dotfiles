# dotfiles

if ! command -v zed >/dev/null 2>&1; then
  if command -v zed-preview >/dev/null 2>&1; then
    alias zed=zed-preview
    alias dfz="EDITOR=zed-preview dotfiles edit"
  fi
else
  alias dfz="EDITOR=zed dotfiles edit"
fi

alias dfcd="cd ${DOTFILES}"

# ls - Use uutils if installed
if command -v uls >/dev/null 2>&1; then
  alias ls='uls --group-directories-first --color=auto --human-readable'
  alias lc='ls -l -a --classify=auto'
fi
alias la='ls -a -l'
alias ll='ls -l'
alias l.='ls -d .*'

# developer
alias dev="cd ${HOME}/Developer"

# ssh
alias sshpw="ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no"

# Install Ghostty term info on target server
ghostty_term() {
  infocmp -x | ssh $@ -SERVER -- tic -x -
}

# Platform specific aliases
case $(uname) in
Darwin)
  # System information
  alias about="system_profiler SPHardwareDataType SPSoftwareDataType SPStorageDataType"
  alias sysver="sw_vers"

  # Rebuild Spotlight index
  alias spotlight-rebuild="sudo mdutil -E /"

  # QuickLook
  alias ql='qlmanage -p "$@" >& /dev/null'

  # Sketch
  alias sketchtool="$(mdfind kMDItemCFBundleIdentifier = 'com.bohemiancoding.sketch3' | head -n 1)/Contents/Resources/sketchtool/bin/sketchtool"

  # Tailscale
  alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"

  # Proxyman
  alias proxyman-cli="/Applications/Proxyman.app/Contents/MacOS/proxyman-cli"

  # View manpage as PDF
  manp() {
    mandoc -T pdf $(man -w $@) | open -f -a Preview
  }

  # View man page in new terminal window
  manx() {
    # Opens in a terminal window
    if [ -n "${2}" ]; then
      open x-man-page://${1}/${2}
    else
      open x-man-page://${1}
    fi
  }
  ;;
Linux)
  # Linux version of macOS pbcopy/pbpaste.
  if command -v xsel >/dev/null 2>&1; then
    alias pbcopy="xsel --clipboard --input"
    alias pbpaste="xsel --clipboard --output"
  fi

  # View man page as PDF
  manp() {
    man -Tpdf $@ | flatpak run org.gnome.Evince
  }

  # View man page in help viewer
  manx() {
    # Use yelp to open man page
    yelp "man:${1}" 2 >/dev/null 2>&1 &
  }

  if command -v flatpak >/dev/null 2>&1; then
    if flatpak info io.github.shiftey.Desktop &>/dev/null; then
      alias github='flatpak run io.github.shiftey.Desktop'
    fi
  fi
  ;;
esac

# vim: set ft=sh ts=2 sw=2 et:
