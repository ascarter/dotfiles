#!/bin/sh

set -eu

# GitHub CLI extensions installer
if command -v gh >/dev/null 2>&1; then
  echo "Install gh extensions"
  gh auth status || true
  for extension in github/gh-copilot; do
    echo "GitHub CLI extension ${extension}"
    gh extension install ${extension} || true
  done
fi

# vim: set ft=sh ts=2 sw=2 et:
