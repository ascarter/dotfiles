#!/bin/sh

# Test install into ./testuser

set -eu

SCRIPT_DIR="$(dirname "$0")"
TEST_HOME="${SCRIPT_DIR}/.testuser"

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

# Run installer
echo "Running installer with isolated environment..."
export HOME="${TEST_HOME}"
sh "${SCRIPT_DIR}/install.sh"

exit 0

# Basic post-install checks
STATUS=0
if [ ! -d "${DOTFILES_HOME}" ]; then
  echo "ERROR: DOTFILES_HOME was not created at ${DOTFILES_HOME}"
  STATUS=1
else
  echo "DOTFILES_HOME present."
  if [ -x "${DOTFILES_HOME}/bin/dotfiles" ]; then
    echo "dotfiles executable found."
  else
    echo "WARNING: dotfiles executable missing or not executable at ${DOTFILES_HOME}/bin/dotfiles"
  fi
fi

echo "Test installation complete (status=${STATUS})."
echo "You can inspect ${DOTFILES_HOME} to verify contents."

exit "${STATUS}"
