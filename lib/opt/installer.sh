# lib/opt/installer.sh — curl-installer driver
#
# Handles TOOL_TYPE=installer recipes that download and pipe a vendor
# install script to bash. Declarative variables replace tool_download hooks.
#
# No shebang — sourced by lib/opt.sh.

# _tool_installer_download
# Downloads TOOL_INSTALL_URL and pipes it to bash with optional env vars
# and arguments:
#   curl -fsSL "$TOOL_INSTALL_URL" | env $TOOL_INSTALL_ENV bash -s -- $TOOL_INSTALL_ARGS
_tool_installer_download() {
  [[ -n "${TOOL_INSTALL_URL:-}" ]] || { error "installer driver: TOOL_INSTALL_URL not set"; return 1; }
  log "download" "${TOOL_CMD} via ${TOOL_INSTALL_URL}"
  # shellcheck disable=SC2086
  curl -fsSL "$TOOL_INSTALL_URL" | env ${TOOL_INSTALL_ENV:-} bash -s -- ${TOOL_INSTALL_ARGS:-}
}
