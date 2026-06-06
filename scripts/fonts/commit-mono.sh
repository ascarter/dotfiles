#!/usr/bin/env bash
#
# Install Commit Mono — static OTF (no variable font in current releases).
# Bump VERSION when a new release matters: https://github.com/eigilnikolajsen/commit-mono/releases

set -eu

: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../.." && pwd)}"
source "${DOTFILES_HOME}/lib/logging.sh"
source "${DOTFILES_HOME}/lib/fonts.sh"

VERSION="1.143"

font_install_github_release \
  --name commit-mono \
  --repo eigilnikolajsen/commit-mono \
  --tag "v${VERSION}" \
  --asset "CommitMono-${VERSION}.zip" \
  --extract "CommitMono-${VERSION}/*.otf"
