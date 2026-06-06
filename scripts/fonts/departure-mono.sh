#!/usr/bin/env bash
#
# Install Departure Mono — single OTF.
# Bump VERSION when a new release matters: https://github.com/rektdeckard/departure-mono/releases

set -eu

: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../.." && pwd)}"
source "${DOTFILES_HOME}/lib/logging.sh"
source "${DOTFILES_HOME}/lib/fonts.sh"

VERSION="1.500"

font_install_github_release \
  --name departure-mono \
  --repo rektdeckard/departure-mono \
  --tag "v${VERSION}" \
  --asset "DepartureMono-${VERSION}.zip" \
  --extract "DepartureMono-${VERSION}/DepartureMono-Regular.otf"
