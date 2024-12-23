case $(uname) in
Darwin)
  # ls
  alias ls="ls -hFH"

  # macOS appearance
  alias darkmode='osascript -e "tell application \"System Events\" to tell appearance preferences to set dark mode to true"'
  alias lightmode='osascript -e "tell application \"System Events\" to tell appearance preferences to set dark mode to false"'
  alias switchmode='osascript -e "tell application \"System Events\" to tell appearance preferences to set dark mode to not dark mode"'

  # System shortcuts
  alias lockscreen="/System/Library/CoreServices/"Menu Extras"/User.menu/Contents/Resources/CGSession -suspend"
  alias ejectall='osascript -e "tell application \"Finder\" to eject (every disk whose ejectable is true)"'

  # System information
  alias about="system_profiler SPHardwareDataType SPSoftwareDataType SPStorageDataType"

  # Use sw_vers for version
  alias sysver="sw_vers"

  # IP addresses

  # ip list
  alias ip='ifconfig | grep "inet " | grep -v 127.0.0.1 | cut -d " " -f2'

  # verbose ip list
  alias ipv="ifconfig -a | perl -nle'/(\d+\.\d+\.\d+\.\d+)/ && print $1'"
  alias ips="ifconfig -a | grep -o 'inet6\? \(addr:\)\?\s\?\(\(\([0-9]\+\.\)\{3\}[0-9]\+\)\|[a-fA-F0-9:]\+\)' | awk '{ sub(/inet6? (addr:)? ?/, \"\"); print }'"

  # local ip
  alias localip="ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'"

  # external ip
  alias wanip="dig +short myip.opendns.com @resolver1.opendns.com"

  # local ip - expects en0 | en1 | ...
  # alias localip="ipconfig getifaddr"

  # Airport utility
  alias airport=/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport

  # Power managment
  alias keepawake="caffeinate -d -i -s"
  alias sleepnow="pmset sleepnow"
  alias batterycapacity="ioreg -w0 -c AppleSmartBattery -b -f | grep -i capacity"

  # QuickLook
  alias ql='qlmanage -p "$@" >& /dev/null'

  # YubiKey
  alias ykman="/Applications/YubiKey\ Manager.app/Contents/MacOS/ykman"

  # Dev tools
  alias extags="/opt/homebrew/bin/ctags"
  alias verifyxcode="spctl --assess --verbose /Applications/Xcode.app"
  alias sketchtool="$(mdfind kMDItemCFBundleIdentifier = 'com.bohemiancoding.sketch3' | head -n 1)/Contents/Resources/sketchtool/bin/sketchtool"

  # BBEdit aliases
  if (( $+commands[bbedit] )); then
    alias bb="bbedit"
    alias bbcl="bbedit --clean"
    alias bbclw="bbedit --clean --new-window"
    alias bbctags="/Applications/BBEdit.app/Contents/Helpers/ctags"
    alias bbd=bbdiff
    alias bbmake="bbr make"
    alias bbp="pbpaste | bbedit --clean --view-top"
    alias bbtags="bbedit --maketags"
    alias bbw="bbedit --new-window"
  fi

  # Tailscale
  alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"

  # Proxyman
  alias proxyman-cli="/Applications/Proxyman.app/Contents/MacOS/proxyman-cli"

  # Apple Podcasts downloads
  alias podcastlib="/Users/acarter/Library/Group Containers/243LU875E5.groups.com.apple.podcasts/Library"
  ;;

Linux)
  alias ls="ls -hFH --group-directories-first --color=never"
  alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'
  alias glock="gnome-screensaver-command --lock"
  alias xlock="xscreensaver-command -lock"

  # Linux version of macOS pbcopy/pbpaste.
  if (( $+commands[xsel] )); then
    alias pbcopy="xsel --clipboard --input"
    alias pbpaste="xsel --clipboard --output"
  fi
  ;;
esac

# dotfiles
alias dfcd="cd ${DOTFILES}"
alias dfedit="$VISUAL ${DOTFILES}"

# zsh
alias resetcomp="rm -f $HOME/.zcompdump && compinit"

# 1Password
if (( $+commands[op] )); then
  alias 1pid="op user get --me --format json | jq .id -r"
fi

# Developer projects
alias dev="cd $HOME/Developer"

# ls
alias ll="ls -l"
alias la="ls -a"
alias lla="ls -la"
alias lsd="ls -l | grep --color=never '^d'"
alias lsz="ls -lAh | grep -m 1 total | sed 's/total //'"
alias filetree="ls -R | grep ":$" | sed -e 's/:$//' -e 's/[^-][^\/]*\//--/g' -e 's/^/ /' -e 's/-/|/'"

# Search/grep
alias devgrep="grep -n -r --exclude='.svn' --exclude='*.swp' --exclude='.git'"

# Find
alias rmempty="find . -type d -empty -print"
alias prune="find -L . -type l -exec rm -- {} +"

# Emacs
alias em="emacs -nw"

# SSH
alias sshpw="ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no"
alias sshagentstart="eval $(ssh-agent -s) && ssh-add -A"

# Stopwatch
alias timer="echo "Timer started. Stop with Ctrl-D." && date && time cat && date"

# Intuitive map function
# For example, to list all directories that contain a certain file:
# find . -name .gitattributes | map dirname
alias map="xargs -n1"

# Canonical hex dump; some systems have this symlinked
command -v hd >/dev/null || alias hd="hexdump -C"

# Resize terminal
alias rs="resize -s 40 120"
alias rst="resize -s 0 120"

# Weather
alias wfc="wttr Snoqualmie"
alias wnow="wttr Snoqualmie format=3"

# Universal Development Container
alias udc="docker run --rm -it --platform=linux/amd64 -v ${PWD}:/workspace -w /workspace mcr.microsoft.com/devcontainers/universal:latest"

# Ruby
alias createrbc="docker volume create ruby-bundle-cache"
alias docked="docker run --rm -it -v ${PWD}:/rails -v ruby-bundle-cache:/bundle -p 3000:3000 ghcr.io/rails/cli"
# alias rails="bin/rails"

# Go
alias gopresent="present -play=true &; open -g http://127.0.0.1:3999; fg"
alias godocw="godoc -http=:6060 -play -q"

# Node.js
alias npmlist="npm list --depth=0"

# Python
alias rmpyc="find . -type f -name \*.pyc -print | xargs rm"
alias pydocv="python -m pydoc"
alias editvenv="bbedit --new-window $VIRTUAL_ENV"
alias pipbrew="CFLAGS="-I/opt/homebrew/include -L/opt/homebrew/lib" pip"
alias pdb="python -m pdb"
alias pyunittest="python -m unittest discover --buffer"
alias pyactivate="source .venv/bin/activate"

if (( $+commands[brew] )); then
  # Add homebrew python aliases
  alias bpython=$(brew --prefix python)/libexec/bin/python
  alias bvenv="$(brew --prefix python)/libexec/bin/python -m venv --clear .venv"
fi

# View HTTP traffic
alias sniff="sudo ngrep -d 'en1' -t '^(GET|POST) ' 'tcp and port 80'"
alias httpdump="sudo tcpdump -i en1 -n -s 0 -w - | grep -a -o -E \"Host\: .*|GET \/.*\""

# Networking
alias tcplisten="lsof -nP -iTCP -sTCP:LISTEN"
alias udplisten="lsof -nP -iUDP"
