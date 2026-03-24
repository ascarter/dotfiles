# lib/opt.sh — sourced library for tool installer scripts
#
# Source this file from tool scripts in tools/:
#   : "${DOTFILES_HOME:=$(cd "$(dirname "$0")/.." && pwd)}"
#   source "${DOTFILES_HOME}/lib/opt.sh"
#
# No shebang — this file is sourced, not executed.
# Does not use set -e internally; callers may set it.

# Load shared display/logging functions (idempotent)
source "${DOTFILES_HOME}/lib/core.sh"

# XDG base dirs with ~/.local fallbacks
: "${XDG_DATA_HOME:=$HOME/.local/share}"
: "${XDG_CACHE_HOME:=$HOME/.cache}"
: "${XDG_STATE_HOME:=$HOME/.local/state}"
: "${XDG_BIN_HOME:=$HOME/.local/bin}"
: "${XDG_OPT_HOME:=$HOME/.local/opt}"
: "${XDG_OPT_BIN:=$XDG_OPT_HOME/bin}"
: "${XDG_OPT_SHARE:=$XDG_OPT_HOME/share}"
export XDG_OPT_HOME XDG_OPT_BIN XDG_OPT_SHARE

# Tool storage layout
#
# XDG_OPT_HOME (~/.local/opt)
#   bin/          (XDG_OPT_BIN)  symlink farm for binaries
#   share/        (XDG_OPT_SHARE) symlink farm for man pages and completions
#   cellar/       (TOOLS_CELLAR)  versioned installs, keyed by tool name
#     <name>/
#       <tag>/    extracted assets
#
# XDG_CACHE_HOME/tools/  (TOOLS_CACHE)  downloaded archives, keyed by tool name
#   <name>/
#
# XDG_STATE_HOME/tools/  (TOOLS_STATE)  installed version receipts
#   <name>        one file per tool, contains the installed tag
#
TOOLS_CELLAR="${XDG_OPT_HOME}/cellar"
TOOLS_CACHE="${XDG_CACHE_HOME}/tools"
TOOLS_STATE="${XDG_STATE_HOME}/tools"
# Convenience aliases used by tool scripts
TOOLS_BIN="${XDG_OPT_BIN}"
TOOLS_SHARE="${XDG_OPT_SHARE}"

# Detect platform: <arch>-<os>
# Produces: aarch64-darwin, aarch64-linux, x86_64-linux
_tool_detect_platform() {
  local arch os
  arch="$(uname -m)"
  case "$(uname -s)" in
    Darwin) os="darwin" ;;
    Linux)  os="linux"  ;;
    *)      os="unknown" ;;
  esac
  case "$arch" in
    arm64) arch="aarch64" ;;
  esac
  printf '%s-%s\n' "$arch" "$os"
}

TOOLS_PLATFORM="$(_tool_detect_platform)"
export TOOLS_PLATFORM

# Ensure required directories exist
mkdir -p "${TOOLS_CELLAR}" "${TOOLS_CACHE}" "${TOOLS_STATE}" "${TOOLS_BIN}" "${TOOLS_SHARE}"

# ---------------------------------------------------------------------------
# Load type-specific drivers
# ---------------------------------------------------------------------------
source "${DOTFILES_HOME}/lib/opt/github.sh"
source "${DOTFILES_HOME}/lib/opt/appimage.sh"
source "${DOTFILES_HOME}/lib/opt/installer.sh"

# ---------------------------------------------------------------------------
# Shared primitives
# ---------------------------------------------------------------------------

# tool_check <cmd>
#
# Guard for tool install. Determines whether to proceed, skip, or confirm.
#   - Already in opt paths → skip (already managed by us)
#   - Found elsewhere (system/brew) → warn and prompt to confirm shadow
#   - Not found → proceed
# During upgrade (DOTFILES_TOOL_UPGRADE=1), always continues — upgrades only
# touch tools that were previously installed.
tool_check() {
  local cmd="$1"
  if [[ -n "${DOTFILES_TOOL_UPGRADE:-}" ]]; then
    return 0
  fi
  if command -v "$cmd" >/dev/null 2>&1; then
    local resolved
    resolved="$(command -v "$cmd")"
    # Already managed by us — skip
    case "$resolved" in
      "$HOME/.local/"*)
        vlog "skip" "${cmd} already installed: ${resolved}"
        TOOLS_INSTALL_SKIPPED=1
        return 1
        ;;
    esac
    # Found elsewhere (system or brew) — confirm before shadowing
    log "$cmd" "found at ${resolved}"
    if ! prompt "Install ${cmd} to opt (will shadow existing)?"; then
      vlog "skip" "${cmd} install declined"
      TOOLS_INSTALL_SKIPPED=1
      return 1
    fi
  fi
  return 0
}

# tool_link <src> [dst]
#
# Creates a symlink: XDG_OPT_HOME/<dst> -> TOOLS_INSTALL_DIR/<src>
# src is relative to TOOLS_INSTALL_DIR.
# dst is relative to XDG_OPT_HOME (e.g. "bin/rg", "share/man/man1/rg.1").
# If dst is omitted, defaults to src (mirrors the archive layout into opt).
tool_link() {
  local src="$1"
  local dst="${2:-$src}"
  local src_path="${TOOLS_INSTALL_DIR}/${src}"
  local dst_path="${XDG_OPT_HOME}/${dst}"

  mkdir -p "$(dirname "$dst_path")"
  ln -sf "$src_path" "$dst_path"
}

# ---------------------------------------------------------------------------
# Version interpolation
# ---------------------------------------------------------------------------

# _tool_interpolate_version <asset> <repo>
#
# If <asset> contains {version}, resolves the tag and applies TOOL_VERSION_MATCH
# to extract the version string. Returns the interpolated asset pattern.
# Sets TOOL_RESOLVED_TAG and TOOL_RESOLVED_VERSION for downstream use.
_tool_interpolate_version() {
  local asset="$1"
  local repo="$2"

  TOOL_RESOLVED_TAG=""
  TOOL_RESOLVED_VERSION=""

  [[ "$asset" == *"{version}"* ]] || { printf '%s' "$asset"; return 0; }

  # Resolve tag (respect tool_latest_tag hook if defined)
  local tag
  if declare -f tool_latest_tag >/dev/null 2>&1; then
    tag="$(tool_latest_tag)"
  else
    tag="$(tool_latest_tag "$repo")"
  fi
  [[ -n "$tag" ]] || { error "_tool_interpolate_version: failed to resolve tag for ${repo}"; return 1; }

  TOOL_RESOLVED_TAG="$tag"

  local version="$tag"
  if [[ -n "${TOOL_VERSION_MATCH:-}" ]]; then
    if [[ "$tag" =~ ${TOOL_VERSION_MATCH} ]]; then
      version="${BASH_REMATCH[1]}"
    else
      error "_tool_interpolate_version: tag '${tag}' does not match TOOL_VERSION_MATCH: ${TOOL_VERSION_MATCH}"
      return 1
    fi
  fi

  TOOL_RESOLVED_VERSION="$version"
  printf '%s' "${asset//\{version\}/$version}"
}

# ---------------------------------------------------------------------------
# Declarative tool driver
# ---------------------------------------------------------------------------
#
# Recipes are pure config files in tools/ (no shebang, no boilerplate).
# The driver sources a recipe to load its variables and optional hooks,
# then executes the standard install flow.
#
# Entry point (called from lib/tool.sh):
#   tool_run_recipe <recipe-path>
#
# Recipe variables — see docs/tool-system.md for the full reference.
#
# Driver flow:
#   1. Source recipe (sets vars, optionally defines hooks)
#   2. Externally managed check (hook or TOOL_TYPE default)
#   3. tool_check $TOOL_CMD       — skip if already installed (unless upgrade)
#   4. tool_platform_check        — hook or TOOL_TYPE default
#   5. tool_download              — hook or tool_gh_install with {version} interpolation
#   6. tool_post_install          — hook or TOOL_TYPE default
#   7. Log completion

_tool_ready_path() {
  local resolved
  resolved="$(command -v "$TOOL_CMD" 2>/dev/null || true)"
  if [[ -n "$resolved" ]]; then
    printf '%s\n' "$resolved"
  else
    printf '%s\n' "${TOOLS_BIN}/${TOOL_CMD}"
  fi
}

# _tool_should_skip <phase>
# Returns 0 if TOOL_SKIP array contains the given phase.
_tool_should_skip() {
  local phase="$1" s
  for s in "${TOOL_SKIP[@]:-}"; do
    [[ "$s" == "$phase" ]] && return 0
  done
  return 1
}

# tool_is_recipe <script>
# Returns 0 if the file is a declarative recipe (no shebang), 1 if legacy.
tool_is_recipe() {
  local first_line
  first_line="$(head -n1 "$1" 2>/dev/null)"
  [[ "$first_line" != "#!"* ]]
}

# tool_run_recipe <recipe-path>
# Sources a declarative recipe and executes the standard install flow.
tool_run_recipe() {
  local recipe="$1"

  [[ -f "$recipe" ]] || { error "tool_run_recipe: not found: ${recipe}"; return 1; }

  # Reset recipe state
  TOOLS_INSTALL_SKIPPED=0
  TOOLS_INSTALL_SKIPPED_REASON=""
  unset TOOL_CMD TOOL_TYPE TOOL_REPO TOOL_BREW TOOL_LINKS TOOL_MAN_PAGES TOOL_COMPLETIONS TOOL_SKIP
  unset TOOL_STRIP_COMPONENTS TOOL_VERSION_ARGS TOOL_VERSION_MATCH TOOL_UPGRADE_COMMAND
  unset TOOL_ASSET_MACOS_ARM64
  unset TOOL_ASSET_LINUX_ARM64 TOOL_ASSET_LINUX_AMD64
  unset TOOL_DESKTOP_ID TOOL_DESKTOP_EXEC TOOL_DESKTOP_ICON_EXT TOOL_APPIMAGE_GLOB
  unset TOOL_INSTALL_URL TOOL_INSTALL_ENV TOOL_INSTALL_ARGS TOOL_UNINSTALL_PATHS TOOL_UNINSTALL_COMMAND
  unset -f tool_download tool_post_install tool_platform_check tool_externally_managed tool_upgrade 2>/dev/null

  # Source the recipe — sets vars and optionally defines hooks
  source "$recipe"

  [[ -n "${TOOL_CMD:-}" ]] || { error "tool_run_recipe: TOOL_CMD not set in ${recipe}"; return 1; }

  # Skip check: TOOL_SKIP array, hook, or TOOL_TYPE=appimage macOS default
  if [[ -n "${DOTFILES_TOOL_SKIP_EXTERNAL:-}" ]]; then
    local phase="install"
    [[ -z "${DOTFILES_TOOL_UPGRADE:-}" ]] || phase="upgrade"
    local is_skipped=0
    if _tool_should_skip "$phase"; then
      is_skipped=1
    elif [[ "${TOOL_TYPE:-}" == "custom" ]]; then
      is_skipped=1
    elif declare -f tool_externally_managed >/dev/null 2>&1; then
      tool_externally_managed && is_skipped=1
    elif [[ "${TOOL_TYPE:-}" == "appimage" && "$(uname -s)" == "Darwin" ]]; then
      is_skipped=1
    fi
    if [[ "$is_skipped" -eq 1 ]]; then
      TOOLS_INSTALL_SKIPPED=1
      TOOLS_INSTALL_SKIPPED_REASON="external"
      vlog "skip" "$(basename "$recipe" .sh) skipped ($phase)"
      return 0
    fi
  fi

  # 1. Skip if already installed (unless upgrading)
  tool_check "$TOOL_CMD" || return 0

  # 2. Platform check (hook or TOOL_TYPE default)
  if declare -f tool_platform_check >/dev/null 2>&1; then
    tool_platform_check
  elif [[ "${TOOL_TYPE:-}" == "appimage" ]]; then
    _tool_appimage_platform_check
  fi

  # 3. If upgrading, prefer hook → declarative command → skip (normal install flow)
  if [[ -n "${DOTFILES_TOOL_UPGRADE:-}" ]]; then
    if declare -f tool_upgrade >/dev/null 2>&1; then
      log "upgrade" "$TOOL_CMD"
      tool_upgrade
      return $?
    elif [[ -n "${TOOL_UPGRADE_COMMAND:-}" ]]; then
      log "upgrade" "$TOOL_CMD"
      $TOOL_UPGRADE_COMMAND
      return $?
    fi
  fi

  # 4. Download (hook → installer driver → GitHub release)
  if declare -f tool_download >/dev/null 2>&1; then
    tool_download
  elif [[ -n "${TOOL_INSTALL_URL:-}" ]]; then
    _tool_installer_download
  elif [[ -n "${TOOL_REPO:-}" ]]; then
    local asset
    asset="$(_tool_resolve_asset)"
    if [[ -z "$asset" ]]; then
      error "tool_run_recipe: no asset for platform ${TOOLS_PLATFORM} in ${recipe}"
      return 1
    fi
    # Interpolate {version} if present in asset pattern
    asset="$(_tool_interpolate_version "$asset" "$TOOL_REPO")" || return 1
    if [[ -n "${TOOL_RESOLVED_TAG:-}" ]]; then
      tool_gh_install "$TOOL_REPO" "$asset" "$TOOL_RESOLVED_TAG"
    else
      tool_gh_install "$TOOL_REPO" "$asset"
    fi
  else
    error "tool_run_recipe: no download method in ${recipe} (set TOOL_REPO, TOOL_INSTALL_URL, or define tool_download)"
    return 1
  fi

  # 5. Nothing to do if download determined we're already current
  if [[ "${TOOLS_INSTALL_SKIPPED:-0}" -eq 1 ]]; then
    return 0
  fi

  # 6. Post-install (hook or TOOL_TYPE default)
  if declare -f tool_post_install >/dev/null 2>&1; then
    tool_post_install
  elif [[ "${TOOL_TYPE:-}" == "appimage" ]]; then
    _tool_appimage_default_post_install
  else
    _tool_default_post_install
  fi

  # 7. Log completion
  log "ready" "${TOOL_CMD} installed: $(_tool_ready_path)"
}
