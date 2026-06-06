#!/usr/bin/env bash
#
# Install Monaspace — variable variant only (Argon, Krypton, Neon, Radon, Xenon).
# Skips the much larger static, nerd-fonts, and webfont variants.
# Bump VERSION when a new release matters: https://github.com/githubnext/monaspace/releases

set -eu

: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../.." && pwd)}"
source "${DOTFILES_HOME}/lib/logging.sh"
source "${DOTFILES_HOME}/lib/fonts.sh"

VERSION="1.400"

font_install_github_release \
  --name monaspace \
  --repo githubnext/monaspace \
  --tag "v${VERSION}" \
  --asset "monaspace-variable-v${VERSION}.zip" \
  --extract 'Variable Fonts/*/*.ttf'
