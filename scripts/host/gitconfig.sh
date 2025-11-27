#!/bin/sh

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
  # Clear existing user config
  gc_clear "user.name"
  gc_clear "user.email"

  # Get full name from system
  fullname=$(get_fullname)

  # GitHub username from gh CLI
  ghuser=$(gh api user --jq '.login' 2>/dev/null || true)
  if [ -z "$ghuser" ]; then
    printf "Not logged into GitHub CLI. Run 'gh auth login' first.\n"
    exit 1
  fi

  # Use GitHub noreply email
  email="${ghuser}@users.noreply.github.com"

  gc_set user.name "$fullname"
  gc_set user.email "$email"

  printf "Set identity: %s <%s>\n" "${fullname}" "${email}"
}

# Configure git credential managers
configure_credentials() {
  # Use GitHub CLI for GitHub authentication
  if command -v gh >/dev/null 2>&1; then
    printf "Enable gh (GitHub) credential helper\n"
    gh_urls="https://github.com https://gist.github.com"
    for url in $gh_urls; do
      gc_clear credential.${url}.helper
    done
    gh auth setup-git
  fi

  # Configure Azure DevOps if GCM is installed
  if command -v git-credential-manager >/dev/null 2>&1; then
    printf "Enable GCM (Azure DevOps) credential helper\n"

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
  # Clear signing keys
  gc_clear user.signingkey
  gc_clear gpg.format
  gc_clear gpg.ssh.program
  gc_clear gpg.program
  gc_clear commit.gpgsign
  gc_clear tag.gpgsign
  gc_clear gpg.ssh.allowedSignersFile

  # Check if GPG is installed and configured
  if ! command -v gpg >/dev/null 2>&1; then
    printf "GPG not installed - skipping signing configuration\n"
    return 1
  fi

  # Get the full path to gpg
  gpg_path=$(command -v gpg)

  # Get the signing key ID from YubiKey
  # Parse colon-separated output: find first secret subkey (ssb) with signing capability (s)
  signing_key=$(gpg --list-secret-keys --with-colons 2>/dev/null | awk -F: '/^ssb/ && $12 ~ /s/ {print $5; exit}' || true)

  if [ -n "$signing_key" ]; then
    printf "YubiKey GPG key: %s\n" "${signing_key}"
    gc_set user.signingkey "$signing_key"
    gc_set gpg.program "$gpg_path"
    gc_set commit.gpgsign true
    gc_set tag.gpgsign true
  else
    printf "No YubiKey GPG key found - skipping signing configuration\n"
  fi
}

# Configure GUI tools
configure_tools() {
  gc_clear diff.guitool
  gc_clear diff.tool
  gc_clear merge.guitool
  gc_clear merge.tool

  # Use opendiff on macOS for gui diff/merge tools
  if command -v opendiff >/dev/null 2>&1; then
    printf "Enable opendiff\n"
    gc_set diff.tool "opendiff"
    gc_set diff.guitool "opendiff"
    gc_set merge.tool "opendiff"
    gc_set merge.guitool "opendiff"
  fi
}

# Configure Git LFS
configure_lfs() {
  if command -v git-lfs >/dev/null 2>&1; then
    printf "Enable Git LFS\n"
    gc_clear filter.lfs.clean
    gc_clear filter.lfs.smudge
    gc_clear filter.lfs.required
    gc_clear filter.lfs.process

    git lfs install
  fi
}

main() {
  # Require GitHub CLI to be logged in
  if ! command -v gh >/dev/null 2>&1; then
    "GitHub CLI (gh) is not installed"
    exit 1
  fi

  printf "Generating %s\n" "${GIT_CONFIG_FILE}"

  configure_user
  configure_credentials
  configure_signing
  configure_tools
  configure_lfs

  printf "Configuration complete\n"
}

main "$@"
