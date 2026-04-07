#!/usr/bin/env bash

# macOS defaults — system and app preferences

set -eu

# Terminal: focus follows mouse
defaults write com.apple.terminal FocusFollowsMouse -string true

# Reduce menu icons (macOS 26 Tahoe+)
defaults write -g NSMenuEnableActionImages -bool NO
