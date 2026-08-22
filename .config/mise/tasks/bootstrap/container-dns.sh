#!/bin/sh
#MISE description="Create the container DNS domain"
#MISE raw=true

if [ "$(uname -s)" != "Darwin" ] || ! command -v container >/dev/null 2>&1; then
  exit 0
fi

if ! container system dns list --quiet | grep -Fxq test; then
  sudo -p 'Container DNS setup (create test) password: ' container system dns create test
fi
