#!/usr/bin/env bash
#USAGE arg "[name]" help="Git user.name"
#USAGE arg "[email]" help="Git user.email"
#MISE description="Configure Git settings"
#MISE quiet=true

GITCONFIG_FILE="${GITCONFIG_FILE:-${HOME}/.gitconfig}"

gh auth status --active || gh auth login --git-protocol=https --web --clipboard
git config set --file ${GITCONFIG_FILE} user.name "${usage_name:-$(gh api user --jq .name)}"
git config set --file ${GITCONFIG_FILE} user.email "${usage_email:-$(gh api user --jq .login)@users.noreply.github.com}"
gh auth setup-git --hostname github.com
