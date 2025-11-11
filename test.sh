#!/bin/sh

# Test install into ./testuser

set -eu

SCRIPT_DIR="$(dirname "$0")"
TEST_HOME="${SCRIPT_DIR}/.testuser"
TEST_DOTFILES_HOME=${TEST_HOME}/.local/share/dotfiles

echo "Test TEST_HOME: ${TEST_HOME}"

if [ -d "${TEST_HOME}" ]; then
  echo "Cleaning existing testuser directory..."
  # Remove only contents, keep directory for permissions.
  # Safer than rm -rf TEST_HOME followed by recreate.
  find "${TEST_HOME}" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
else
  echo "Creating testuser directory..."
  mkdir -p "${TEST_HOME}"
fi

# Create TEST_DOTFILES_HOME
mkdir -p "${TEST_DOTFILES_HOME}"

# Overlay local working tree changes using rsync
if ! command -v rsync >/dev/null 2>&1; then
  echo "ERROR: rsync not installed (needed to overlay local changes)" >&2
  exit 1
fi

rsync -a --exclude='.git/' --exclude='.testuser/' "${SCRIPT_DIR}/" "${TEST_DOTFILES_HOME}/"

# dotfiles init
export HOME="${TEST_HOME}"
echo "${HOME} dotfiles init"
sh "${TEST_DOTFILES_HOME}/bin/dotfiles" init
sh "${TEST_DOTFILES_HOME}/bin/dotfiles" sync

# Post-install checks
STATUS=0
if [ ! -d "${TEST_DOTFILES_HOME}" ]; then
  echo "ERROR: TEST_DOTFILES_HOME was not created at ${TEST_DOTFILES_HOME}"
  STATUS=1
else
  echo "TEST_DOTFILES_HOME present."
  if [ -x "${TEST_DOTFILES_HOME}/bin/dotfiles" ]; then
    echo "dotfiles executable found."
  else
    echo "WARNING: dotfiles executable missing or not executable at ${TEST_DOTFILES_HOME}/bin/dotfiles"
  fi
fi

echo "Test installation complete (status=${STATUS})."
echo "You can inspect ${TEST_DOTFILES_HOME} to verify contents."

exit "${STATUS}"
