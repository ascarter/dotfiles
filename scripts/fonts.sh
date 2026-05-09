#!/usr/bin/env bash

# Install fonts
#
# Installs fonts from a zip file to the user's local fonts directory.
# Usage: fonts.sh /path/to/fonts.zip
#
# Prefers OTF fonts; falls back to TTF if no OTF files are found.
# Extracts font files flattened (no subdirectories) and excludes
# macOS resource fork (._) files.

set -eu

FONTS_ZIP_FILE="${1:-}"

if [ -z "${FONTS_ZIP_FILE}" ] || ! [ -f "${FONTS_ZIP_FILE}" ]; then
  echo "Usage: $0 /path/to/fonts.zip"
  exit 1
fi

case "$(uname -s)" in
  Darwin)
    FONTS_DIR="${HOME}/Library/Fonts"
    ;;
  Linux)
    FONTS_DIR="${HOME}/.local/share/fonts"
    ;;
  *)
    echo "Unsupported OS: $(uname -s)"
    exit 1
    ;;
esac

mkdir -p "${FONTS_DIR}"

# Prefer OTF; fall back to TTF if archive contains no OTF files
if unzip -l "${FONTS_ZIP_FILE}" "*.otf" 2>/dev/null | grep -qi '\.otf$'; then
  unzip -o -j "${FONTS_ZIP_FILE}" "*.otf" -x "._*" -d "${FONTS_DIR}"
elif unzip -l "${FONTS_ZIP_FILE}" "*.ttf" 2>/dev/null | grep -qi '\.ttf$'; then
  unzip -o -j "${FONTS_ZIP_FILE}" "*.ttf" -x "._*" -d "${FONTS_DIR}"
else
  echo "No OTF or TTF fonts found in ${FONTS_ZIP_FILE}"
  exit 1
fi

# Update font cache on Linux
if [ "$(uname -s)" = "Linux" ]; then
  fc-cache -f -v "${FONTS_DIR}"
fi

echo "Fonts installed to ${FONTS_DIR}"
