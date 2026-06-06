#!/usr/bin/env bash
#
# Install IBM Plex — Mono (static OTF), Sans Variable, Serif Variable.
#
# IBM Plex publishes each subfamily under its own tag like
# `@ibm/plex-<subfamily>@<version>`. Bump each version variable independently.
#
# Variable subfamily filenames are self-prefixed (e.g. "IBM Plex Sans Var-Roman.ttf"
# and "IBM Plex Serif Var-Roman.ttf"), so they do not collide when installed flat.
#
# https://github.com/IBM/plex/releases

set -eu

: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../.." && pwd)}"
source "${DOTFILES_HOME}/lib/logging.sh"
source "${DOTFILES_HOME}/lib/fonts.sh"

MONO_VERSION="1.1.0"
SANS_VAR_VERSION="0.2.0"
SERIF_VAR_VERSION="2.0.0"

# Mono (static OTF)
font_install_github_release \
  --name ibm-plex-mono \
  --repo IBM/plex \
  --tag "@ibm/plex-mono@${MONO_VERSION}" \
  --asset 'ibm-plex-mono.zip' \
  --extract 'ibm-plex-mono/fonts/complete/otf/*.otf'

# Sans Variable
font_install_github_release \
  --name ibm-plex-sans-variable \
  --repo IBM/plex \
  --tag "@ibm/plex-sans-variable@${SANS_VAR_VERSION}" \
  --asset 'plex-sans-variable.zip' \
  --extract 'fonts/complete/ttf/*.ttf'

# Serif Variable
font_install_github_release \
  --name ibm-plex-serif-variable \
  --repo IBM/plex \
  --tag "@ibm/plex-serif-variable@${SERIF_VAR_VERSION}" \
  --asset 'plex-serif-variable.zip' \
  --extract 'plex-serif-variable/complete/ttf/*.ttf'
