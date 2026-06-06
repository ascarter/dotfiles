#!/usr/bin/env bash
#
# Install Adobe Source Code Pro — variable OTF (VF).
#
# Adobe uses a composite release tag combining upright (UV), italic (IV), and
# variable (VFV) versions. The TAG must match an existing release on GitHub
# exactly; bump VF_VERSION alongside any tag change.
#
# https://github.com/adobe-fonts/source-code-pro/releases

set -eu

: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../.." && pwd)}"
source "${DOTFILES_HOME}/lib/logging.sh"
source "${DOTFILES_HOME}/lib/fonts.sh"

TAG="2.042R-u/1.062R-i/1.026R-vf"
VF_VERSION="1.026R"

font_install_github_release \
  --name source-code-pro \
  --repo adobe-fonts/source-code-pro \
  --tag "${TAG}" \
  --asset "VF-source-code-VF-${VF_VERSION}.zip" \
  --extract 'VF/*.otf'
