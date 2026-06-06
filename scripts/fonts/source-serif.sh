#!/usr/bin/env bash
#
# Install Adobe Source Serif — variable OTF from the Desktop bundle.
# Bump VERSION when a new release matters: https://github.com/adobe-fonts/source-serif/releases
# Adobe tags this repo NN.NNNR (e.g. 4.005R); the asset embeds the bare version.

set -eu

: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../.." && pwd)}"
source "${DOTFILES_HOME}/lib/logging.sh"
source "${DOTFILES_HOME}/lib/fonts.sh"

VERSION="4.005"

font_install_github_release \
  --name source-serif \
  --repo adobe-fonts/source-serif \
  --tag "${VERSION}R" \
  --asset "source-serif-${VERSION}_Desktop.zip" \
  --extract "source-serif-${VERSION}_Desktop/VAR/*.otf"
