#!/usr/bin/env bash
#
# Install Inter — variable TTF (Inter and Inter Italic).
# Bump VERSION when a new release matters: https://github.com/rsms/inter/releases

set -eu

: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../.." && pwd)}"
source "${DOTFILES_HOME}/lib/logging.sh"
source "${DOTFILES_HOME}/lib/fonts.sh"

VERSION="4.1"

font_install_github_release \
  --name inter \
  --repo rsms/inter \
  --tag "v${VERSION}" \
  --asset "Inter-${VERSION}.zip" \
  --extract 'InterVariable.ttf' \
  --extract 'InterVariable-Italic.ttf'
