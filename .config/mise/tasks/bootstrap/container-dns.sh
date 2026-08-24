#!/bin/sh
#MISE description="Create container DNS domain"
#MISE interactive=true
#USAGE arg "[domain]" help="DNS domain (default test)" default="test"

[ "$(uname -s)" = "Darwin" ] || exit 0
command -v container >/dev/null 2>&1 || exit 0

if ! container system dns list --quiet | grep -Fxq "${usage_domain}"; then
  sudo -p 'Container DNS setup (create ${usage_domain}) password: ' container system dns create ${usage_domain}
fi
