#!/bin/sh

set -eu

# GitHub CLI extensions installer
if command -v gh >/dev/null 2>&1; then
  gh auth status || true
  for extension in github/gh-copilot; do
    gh extension install ${extension} || true
  done
fi
