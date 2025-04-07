#!/bin/sh

set -eu

XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}

# Ruby
echo "Configuring Ruby (rbenv)"
curl -fsSL https://rbenv.org/install.sh | bash
# Use eval with sh instead of bash
eval "$(~/.rbenv/bin/rbenv init - --no-rehash sh)"
rbenv --version