#!/bin/sh
#MISE description = "Curl install script"
#MISE output = "keep-order"
#MISE quiet = true
#MISE hide = true
#USAGE arg "<name>" help="Tool name"
#USAGE arg "<url>" help="Install script URL"
#USAGE arg "[command]" help="Install command (default sh)" default="sh"

set -eu

if command -v "${usage_name}" >/dev/null 2>&1; then
  echo "${usage_name} is installed"
  exit 0
fi

curl -fsSL "${usage_url}" | "${usage_command}"
