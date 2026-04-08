#!/usr/bin/env bash

# Install fonts
#
# Installs fonts from a zip file to the user's local fonts directory.
# Usage: fonts.sh /path/to/fonts.zip
#
# Fonts are in a zip archive in a flat structure (no subdirectories)
# and will be extracted to user's fonts directory

set -eu

FONTS_ZIP_FILE="${1:-}"

if [ -z "${FONTS_ZIP_FILE}" ] || ! [ -f "${FONTS_ZIP_FILE}" ]; then
  echo "Usage: $0 /path/to/fonts.zip"
  exit 1
fi

case "$(uname -s)" in
  Darwin)
    FONTS_DIR="${HOME}/Library/Fonts"
    mkdir -p "${FONTS_DIR}"
    unzip -o "${FONTS_ZIP_FILE}" -d "${FONTS_DIR}"
    ;;
  Linux)
    FONTS_DIR="${HOME}/.local/share/fonts"
    mkdir -p "${FONTS_DIR}"
    unzip -o "${FONTS_ZIP_FILE}" -d "${FONTS_DIR}"
    fc-cache -f -v
    ;;
esac

echo "Fonts installed to ${FONTS_DIR}"
