#!/usr/bin/env bash
#
# Install JetBrains Mono — variable TTF.
# Bump VERSION when a new release matters: https://github.com/JetBrains/JetBrainsMono/releases

set -eu

: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../.." && pwd)}"
source "${DOTFILES_HOME}/lib/logging.sh"
source "${DOTFILES_HOME}/lib/fonts.sh"

VERSION="2.304"

font_install_github_release \
  --name jetbrains-mono \
  --repo JetBrains/JetBrainsMono \
  --tag "v${VERSION}" \
  --asset "JetBrainsMono-${VERSION}.zip" \
  --extract 'fonts/variable/*.ttf'
