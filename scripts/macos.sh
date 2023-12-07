#!/bin/sh

# Defaults - Clear key
_clearDefaultKey() {
  local domain=${1}
  local prefKey=${2}

  defaults delete ${domain} ${prefKey}
}

# Defaults - Add key to dictionary
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

  _clearDefaultKey ${domain} ${prefKey}
  _writeDefaultDictAdd ${domain} ${prefKey} "Move Window to Left Side of Screen" "@~^\U2190"
  _writeDefaultDictAdd ${domain} ${prefKey} "Move Window to Right Side of Screen" "@~^\U2192"
}

_setWindowKeys
