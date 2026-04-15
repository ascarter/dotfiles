# RPM repository helpers.
# Provides add_repo() for idempotent third-party repo setup.
# Sourced by host bootstrap scripts; requires lib/logging.sh.

# Idempotent guard
[[ -n "${_DOTFILES_RPM_LOADED:-}" ]] && return 0
_DOTFILES_RPM_LOADED=1

# Add an RPM repository from a remote .repo file URL.
# Skips if the target repo file already exists in /etc/yum.repos.d/.
# Works with both dnf and rpm-ostree (both read the same repo configs).
add_repo() {
  local repo_url="${1}"
  [ -n "$repo_url" ] || abort "repo URL required"
  local repo_file
  repo_file="$(basename "${1}")"
  local repo_path="/etc/yum.repos.d/${repo_file}"

  if [ -f "$repo_path" ]; then
    vlog "repo" "${repo_file} already configured"
    return 0
  fi

  log "repo" "Adding ${repo_path}"
  curl -fsSL "${repo_url}" | sudo tee "${repo_path}" >/dev/null || warn "repo" "failed to add ${repo_url}"
}
