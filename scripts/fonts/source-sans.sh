#!/usr/bin/env bash
#
# Install Adobe Source Sans — variable OTF (VF).
# Bump VERSION when a new release matters: https://github.com/adobe-fonts/source-sans/releases
# Adobe uses tags of the form NN.NNNR (e.g. 3.052R).

set -eu

: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../.." && pwd)}"
source "${DOTFILES_HOME}/lib/logging.sh"
source "${DOTFILES_HOME}/lib/fonts.sh"

VERSION="3.052R"

font_install_github_release \
  --name source-sans \
  --repo adobe-fonts/source-sans \
  --tag "${VERSION}" \
  --asset "VF-source-sans-${VERSION}.zip" \
  --extract 'VF/*.otf'
