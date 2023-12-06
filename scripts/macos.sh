#!/bin/sh

# Set window shortcut keys
defaults write .GlobalPreferences NSUserKeyEquivalents "$(<${DOTFILES}/share/macos/NSUserKeyEquivalents.plist)"
