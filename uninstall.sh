#!/bin/sh
#
# Uninstall script for my dotfiles

set -ueo pipefail

HOMEDIR="${1:-${HOME}}"
DOTFILES="${DOTFILES:-${2:-${HOMEDIR}/.config/dotfiles}}"
SRCDIR="${DOTFILES}/home"

# Remove symlinks and restore backups
for f in $(find ${SRCDIR} -type f -print); do
  t=${HOMEDIR}/.${f#${SRCDIR}/}
  if [ -h "${t}" ]; then
    echo "Removing symlink ${t}"
    rm "${t}"

    if [ -f "${t}.orig" ]; then
      echo "Restoring backup ${t}.orig -> ${t}"
      mv "${t}.orig" "${t}"
    fi
  fi
done

# Remove zshenv
if [ -f "${HOMEDIR}/.zshenv" ]; then
  rm "${HOMEDIR}/.zshenv"
fi
