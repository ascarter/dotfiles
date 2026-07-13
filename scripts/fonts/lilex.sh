#!/usr/bin/env bash
#
# Install Lilex and LilexDuo — variable TTFs.
# Bump VERSION when a new release matters: https://github.com/mishamyrt/Lilex/releases

set -eu

: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../.." && pwd)}"
source "${DOTFILES_HOME}/lib/logging.sh"
source "${DOTFILES_HOME}/lib/fonts.sh"

VERSION="2.700"

font_install_github_release \
  --name lilex \
  --repo mishamyrt/Lilex \
  --tag "${VERSION}" \
  --asset "Lilex.zip" \
  --extract 'variable/*.ttf'

font_install_github_release \
  --name lilex-duo \
  --repo mishamyrt/Lilex \
  --tag "${VERSION}" \
  --asset "LilexDuo.zip" \
  --extract 'variable/*.ttf'
