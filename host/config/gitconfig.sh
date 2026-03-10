#!/usr/bin/env bash

# Generate machine-specific git configuration at ~/.gitconfig
#
# This script configures:
# - User identity (from gh CLI + system fullname)
# - Credentials (gh CLI for GitHub, GCM for Azure DevOps if available)
# - Commit signing (GPG with YubiKey if available)
# - GUI tools (opendiff on macOS)
# - Git LFS (if installed)
#
# Machine-independent settings (aliases, colors, etc.) are in $XDG_CONFIG_HOME/git/config

set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../.." && pwd)}"
source "${DOTFILES_HOME}/lib/core.sh"

GIT_CONFIG_FILE="${HOME}/.gitconfig"

get_fullname() {
  fullname=
  case "$(uname -s)" in
    Darwin) fullname=$(id -F 2>/dev/null) ;;
    Linux) fullname=$(getent passwd "$USER" 2>/dev/null | cut -d: -f5 | cut -d, -f1) ;;
  esac
  printf '%s\n' "${fullname:-$USER}"
}

gc_clear() {
  git config unset --file "${GIT_CONFIG_FILE}" --all "$1" 2>/dev/null || true
}

gc_set() {
  git config set --file "${GIT_CONFIG_FILE}" "$1" "$2"
}

gc_append() {
  git config set --file "${GIT_CONFIG_FILE}" --append "$1" "$2"
}

# Configure user identity
configure_user() {
  gc_clear "user.name"
  gc_clear "user.email"

  fullname=$(get_fullname)

  if ! gh auth status 2>/dev/null; then
    gh auth login
  fi

  ghuser=$(gh api user --jq '.login' 2>/dev/null || true)
  if [ -z "$ghuser" ]; then
    abort "Not logged into GitHub CLI. Run 'gh auth login' first."
  fi

  email="${ghuser}@users.noreply.github.com"

  gc_set user.name "$fullname"
  gc_set user.email "$email"

  log "user" "${fullname} <${email}>"
}

# Configure git credential managers
configure_credentials() {
  if command -v gh >/dev/null 2>&1; then
    log "credentials" "gh (GitHub)"
    gh_urls="https://github.com https://gist.github.com"
    for url in $gh_urls; do
      gc_clear credential.${url}.helper
    done
    gh auth setup-git
  fi

  if command -v git-credential-manager >/dev/null 2>&1; then
    log "credentials" "GCM (Azure DevOps)"
    az_urls="https://dev.azure.com https://*.visualstudio.com"
    for url in $az_urls; do
      gc_clear credential.${url}.helper
      gc_clear credential.${url}.useHttpPath
      gc_clear credential.${url}.azreposCredentialType

      gc_append credential.${url}.helper ''
      gc_append credential.${url}.helper "$(command -v git-credential-manager)"
      gc_set credential.${url}.useHttpPath true
      gc_set credential.${url}.azreposCredentialType oauth
    done
  fi
}

# Configure commit signing with GPG
configure_signing() {
  gc_clear user.signingkey
  gc_clear gpg.format
  gc_clear gpg.ssh.program
  gc_clear gpg.program
  gc_clear commit.gpgsign
  gc_clear tag.gpgsign
  gc_clear gpg.ssh.allowedSignersFile

  if ! command -v gpg >/dev/null 2>&1; then
    log "signing" "GPG not installed — skipping"
    return 0
  fi

  gpg_path=$(command -v gpg)
  signing_key=$(gpg --list-secret-keys --with-colons 2>/dev/null | awk -F: '/^ssb/ && $12 ~ /s/ {print $5; exit}' || true)

  if [ -n "$signing_key" ]; then
    log "signing" "YubiKey GPG key: ${signing_key}"
    gc_set user.signingkey "$signing_key"
    gc_set gpg.program "$gpg_path"
    gc_set commit.gpgsign true
    gc_set tag.gpgsign true
  else
    log "signing" "no YubiKey GPG key found — skipping"
  fi
}

# Configure GUI tools
configure_tools() {
  gc_clear diff.guitool
  gc_clear diff.tool
  gc_clear merge.guitool
  gc_clear merge.tool

  if command -v opendiff >/dev/null 2>&1; then
    log "tools" "opendiff"
    gc_set diff.tool "opendiff"
    gc_set diff.guitool "opendiff"
    gc_set merge.tool "opendiff"
    gc_set merge.guitool "opendiff"
  fi
}

# Configure Git LFS
configure_lfs() {
  if command -v git-lfs >/dev/null 2>&1; then
    log "lfs" "enabling Git LFS"
    gc_clear filter.lfs.clean
    gc_clear filter.lfs.smudge
    gc_clear filter.lfs.required
    gc_clear filter.lfs.process

    git lfs install
  fi
}

main() {
  # Enable homebrew if installed
  if [[ -d /opt/homebrew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -d /home/linuxbrew/.linuxbrew ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  fi

  command -v gh >/dev/null 2>&1 || abort "GitHub CLI (gh) is not installed"

  log "gitconfig" "Generating ${GIT_CONFIG_FILE}"

  configure_user
  configure_credentials
  configure_signing
  configure_tools
  configure_lfs

  log "gitconfig" "complete"
}

main "$@"
