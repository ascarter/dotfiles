#!/usr/bin/env bash
#
# Install JuliaMono — all TTFs from the ttf tarball.
# Bump VERSION when a new release matters: https://github.com/cormullion/juliamono/releases

set -eu

: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../.." && pwd)}"
source "${DOTFILES_HOME}/lib/logging.sh"
source "${DOTFILES_HOME}/lib/fonts.sh"

VERSION="0.062"

font_install_github_release \
  --name julia-mono \
  --repo cormullion/juliamono \
  --tag "v${VERSION}" \
  --asset 'JuliaMono-ttf.tar.gz' \
  --extract '*.ttf'
