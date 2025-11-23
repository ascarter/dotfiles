#!/bin/sh

# macOS host provisioning script

set -eu

abort() {
  printf "%s\n" "$*" >&2
  exit 1
}

[ "$(uname -s)" == "Darwin" ] ||  abort "macOS only"

echo "Provisioning macOS host"

# Xcode command line tools
if ! [ -e /Library/Developer/CommandLineTools ]; then
  echo "Installing command line tools..."
  xcode-select --install
  read -p "Press [Enter] when installation completes..." -n1 -s
  echo
  sudo xcodebuild -runFirstLaunch
else
  echo "XCode command line tools OK"
fi

# Enable developer mode
echo "Enabling developer mode"
spctl developer-mode enable-terminal 2>/dev/null || true

# Terminal preferences
echo "Setting Terminal preferences"
defaults write com.apple.terminal FocusFollowsMouse -string true

echo "macOS provisioning complete"
