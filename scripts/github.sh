#!/bin/sh

set -eu

# Enable 1Password plugins
if [ -f "${XDG_CONFIG_HOME}/op/plugins.sh" ]; then
  source "${XDG_CONFIG_HOME}/op/plugins.sh"
fi

# GitHub CLI extensions installer
if command -v gh >/dev/null 2>&1; then
  echo "Install gh extensions"
  gh auth status || true
  for extension in github/gh-copilot; do
    echo "GitHub CLI extension ${extension}"
    gh extension install ${extension} || true
  done

  # Generate GitHub Copilot aliases
  if gh extension list | grep -q copilot; then
    mkdir -p ${DOTFILES_CONFIG}
    gh copilot alias -- bash >"${DOTFILES_CONFIG}/gh-copilot-bash.sh"
    gh copilot alias -- zsh >"${DOTFILES_CONFIG}/gh-copilot-zsh.sh"
    echo "GitHub Copilot aliases generated in ${DOTFILES_CONFIG}"
  fi
fi

# vim: set ft=sh ts=2 sw=2 et:
