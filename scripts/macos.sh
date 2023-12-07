#!/bin/sh

# Add key to dictionary
_writeDefaultDictAdd() {
  local domain=${1}
  local prefKey=${2}
  local key=${3}
  local value=${4}

  defaults write ${domain} ${prefKey} -dict-add "${key}" "${value}"
}

# Set window shortcut keys
_setWindowKeys() {
  local domain=.GlobalPreferences
  local prefKey=NSUserKeyEquivalents

  # Shortcut keys:
  # --------------
  # Control     ⌃   ^
  # Option      ⌥   ~
  # Command     ⌘   @
  # Return      ↩︎   \U21a9
  # Left Arrow  ←   \U2190
  # Up Arrow    ↑   \U2191
  # Right Arrow →   \U2192
  # Down Arrow  ↓   \U2193
  # Open Paren  (   \U0028
  # Close Paren )   \U0029

  _writeDefaultDictAdd ${domain} ${prefKey} "Enter Full Screen" "@~^\U21a9"
  _writeDefaultDictAdd ${domain} ${prefKey} "Exit Full Screen" "@~^\U21a9"
  _writeDefaultDictAdd ${domain} ${prefKey} "Make Window Full Screen" "@~^\U21a9"
  _writeDefaultDictAdd ${domain} ${prefKey} "Move to Apple Studio Display" "@~^\U2191"
  _writeDefaultDictAdd ${domain} ${prefKey} "Move to Built-in Retina Display" "@~^\U2193"
  _writeDefaultDictAdd ${domain} ${prefKey} "Move Window to Desktop" "~^\U21a9"
  _writeDefaultDictAdd ${domain} ${prefKey} "Move Window to Left Side of Screen" "~^\U2190"
  _writeDefaultDictAdd ${domain} ${prefKey} "Move Window to Right Side of Screen" "~^\U2192"
  _writeDefaultDictAdd ${domain} ${prefKey} "Replace Tiled Window" "@~^\U2191"
  _writeDefaultDictAdd ${domain} ${prefKey} "Revert" "~^\U21a9"
  _writeDefaultDictAdd ${domain} ${prefKey} "Tile Window to Left of Screen" "@~^\U2190"
  _writeDefaultDictAdd ${domain} ${prefKey} "Tile Window to Left Side of Screen" "@~^\U2190"
  _writeDefaultDictAdd ${domain} ${prefKey} "Tile Window to Right of Screen" "@~^\U2192"
  _writeDefaultDictAdd ${domain} ${prefKey} "Tile Window to Right Side of Screen" "@~^\U2192"

  # Add work displays
  if [[ "acartermbp" -eq $(hostname -s) ]]; then
    _writeDefaultDictAdd ${domain} ${prefKey} "Move to DELL P2721Q \U00281\U0029" "@~^\U2191"
    _writeDefaultDictAdd ${domain} ${prefKey} "Move to DELL P2721Q \U00282\U0029" "@~^\U2191"
  fi
}

_setWindowKeys
