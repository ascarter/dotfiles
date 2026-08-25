#!/bin/sh
#MISE description = "Curl install script"
#MISE output = "keep-order"
#MISE quiet = true
#MISE hide = true
#USAGE arg "<name>" help="Tool name"
#USAGE arg "<url>" help="Install script URL"
#USAGE arg "[command]" help="Install command (default sh)" default="sh"

set -eu

command -v "${usage_name}" >/dev/null 2>&1 && exit 0
curl -fsSL "${usage_url}" | "${usage_command}"
