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

# tool_latest_tag <owner/repo>
# Prints the latest stable (non-draft, non-prerelease) release tag for the given repo.
tool_latest_tag() {
  local repo="$1"
  gh release list --repo "$repo" --limit 100 \
    --json tagName,isLatest,isPrerelease,isDraft \
    --jq 'map(select((.isDraft | not) and (.isPrerelease | not))) | (map(select(.isLatest == true))[0].tagName // .[0].tagName // empty)'
}

# tool_installed_tag <owner/repo>
# Reads the state file for the tool. Prints tag or "none".
tool_installed_tag() {
  local repo="$1"
  local name="${repo##*/}"
  local state_file="${TOOLS_STATE}/${name}"
  if [[ -f "$state_file" ]]; then
    cat "$state_file"
  else
    printf 'none\n'
  fi
}

# tool_gh_install <owner/repo> <asset-glob> [tag]
#
# Downloads and extracts a GitHub release asset.
# After completion, sets:
#   TOOLS_INSTALL_DIR  — versioned install directory (TOOLS_CELLAR/<name>/<tag>/)
#   TOOLS_INSTALL_TAG  — resolved tag
#
# Handles:
#   .tar.gz  — tar -xzf to versioned dir
#   .zip     — unzip to versioned dir
#   .gz      — gunzip to plain binary in versioned dir (non-tar)
#   <no ext> — copy binary + chmod +x
tool_gh_install() {
  local repo="$1"
  local asset_glob="$2"
  local tag="${3:-}"
  local name="${repo##*/}"
  local state_file="${TOOLS_STATE}/${name}"

  # Resolve tag if not provided. Default is the latest stable release.
  if [[ -z "$tag" ]]; then
    tag="$(tool_latest_tag "$repo")" || { error "tool_gh_install: failed to resolve tag for ${repo}"; return 1; }
  fi

  if [[ -z "$tag" ]]; then
    error "tool_gh_install: could not determine tag for ${repo}"
    return 1
  fi

  TOOLS_INSTALL_DIR="${TOOLS_CELLAR}/${name}/${tag}"
  TOOLS_INSTALL_TAG="$tag"
  export TOOLS_INSTALL_DIR TOOLS_INSTALL_TAG

  # Skip if already installed at this tag
  local installed_tag
  installed_tag="$(tool_installed_tag "$repo")"
  if [[ "$installed_tag" == "$tag" && -d "$TOOLS_INSTALL_DIR" ]]; then
    vlog "skip" "${name} at ${tag}"
    TOOLS_INSTALL_SKIPPED=1
    return 0
  fi

  local cache_dir="${TOOLS_CACHE}/${name}"
  mkdir -p "$cache_dir" "$TOOLS_INSTALL_DIR"

  # Download asset
  log "download" "${repo} ${tag}"
  gh release download "$tag" \
    --repo "$repo" \
    --pattern "$asset_glob" \
    --dir "$cache_dir" \
    --clobber || { error "tool_gh_install: download failed for ${repo} ${tag}"; return 1; }

  # Find the downloaded file
  local asset_file
  asset_file="$(find "$cache_dir" -maxdepth 1 -name "$asset_glob" | head -n1)"
  if [[ -z "$asset_file" ]]; then
    error "tool_gh_install: no asset matching ${asset_glob} found in ${cache_dir}"
    return 1
  fi

  # Extract based on format
  local filename
  filename="$(basename "$asset_file")"

  if [[ "$filename" == *.tar.gz || "$filename" == *.tgz ]]; then
    tar -xzf "$asset_file" -C "$TOOLS_INSTALL_DIR" --strip-components="${TOOL_STRIP_COMPONENTS:-0}" || { error "tool_gh_install: tar extraction failed"; return 1; }
  elif [[ "$filename" == *.zip ]]; then
    unzip -q -o "$asset_file" -d "$TOOLS_INSTALL_DIR" || { error "tool_gh_install: unzip extraction failed"; return 1; }
    # Strip leading directory components from zip if requested
    if [[ -n "${TOOL_STRIP_COMPONENTS:-}" && "${TOOL_STRIP_COMPONENTS:-0}" -gt 0 ]]; then
      local nested_dir
      nested_dir="$(find "$TOOLS_INSTALL_DIR" -mindepth 1 -maxdepth 1 -type d | head -n1)"
      if [[ -n "$nested_dir" ]]; then
        mv "$nested_dir"/* "$TOOLS_INSTALL_DIR"/ 2>/dev/null || true
        rmdir "$nested_dir" 2>/dev/null || true
      fi
    fi
  elif [[ "$filename" == *.gz ]]; then
    # Non-tar gzip: decompress to a binary named after the tool
    gunzip -c "$asset_file" > "${TOOLS_INSTALL_DIR}/${name}" || { error "tool_gh_install: gunzip failed"; return 1; }
    chmod +x "${TOOLS_INSTALL_DIR}/${name}"
  else
    # Plain binary: copy and make executable
    cp "$asset_file" "${TOOLS_INSTALL_DIR}/${filename}" || { error "tool_gh_install: copy failed"; return 1; }
    chmod +x "${TOOLS_INSTALL_DIR}/${filename}"
  fi

  # Record installed tag
  printf '%s\n' "$tag" > "$state_file"
  log "install" "${name} ${tag} -> ${TOOLS_INSTALL_DIR}"
}

# tool_strip_quarantine <path>
#
# Strips com.apple.quarantine from an unsigned binary on macOS.
# No-op on Linux or when the binary is already code-signed.
tool_strip_quarantine() {
  [[ "$(uname -s)" == Darwin ]] || return 0
  local target="${1:-}"
  [[ -n "$target" && -f "$target" ]] || { error "tool_strip_quarantine: path required"; return 1; }

  if codesign -d "$target" >/dev/null 2>&1; then
    log "quarantine" "already signed: ${target}"
    return 0
  fi

  log "quarantine" "stripping com.apple.quarantine: ${target}"
  xattr -dr com.apple.quarantine "$target" 2>/dev/null || true
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
# AppImage helpers
# ---------------------------------------------------------------------------
#
# Shared helpers for tools distributed as AppImages (Linux-only).
# Provides: link binary, extract desktop integration assets, uninstall cleanup.

# tool_appimage_link <glob>
#
# Finds the AppImage matching <glob> in TOOLS_INSTALL_DIR, makes it executable,
# and symlinks it to TOOLS_BIN/$TOOL_CMD.
# Sets TOOL_APPIMAGE to the resolved path for use by tool_appimage_desktop.
tool_appimage_link() {
  local glob="$1"
  local appimage
  appimage="$(find "$TOOLS_INSTALL_DIR" -name "$glob" | head -n1)"
  [[ -n "$appimage" ]] || { error "AppImage not found in ${TOOLS_INSTALL_DIR}"; return 1; }
  chmod +x "$appimage"
  ln -sf "$appimage" "${TOOLS_BIN}/${TOOL_CMD}"
  TOOL_APPIMAGE="$appimage"
}

# tool_appimage_desktop <desktop_id> <exec_line>
#
# Extracts the AppImage (via --appimage-extract), installs the .desktop file and
# icon into XDG_DATA_HOME, and normalizes the Exec= line.
#
#   desktop_id  — base name of the .desktop file without extension
#                 (e.g. "com.mitchellh.ghostty", "obsidian")
#   exec_line   — replacement value for the Exec= key (e.g. "obsidian %u")
#
# Requires TOOL_APPIMAGE to be set (call tool_appimage_link first).
tool_appimage_desktop() {
  local desktop_id="$1"
  local exec_line="$2"
  local appimage="${TOOL_APPIMAGE:?TOOL_APPIMAGE not set — call tool_appimage_link first}"

  local extract_dir
  extract_dir="$(mktemp -d -t "${TOOL_CMD}-extract.XXXXXXXX")"

  (cd "$extract_dir" && "$appimage" --appimage-extract >/dev/null 2>&1) \
    || { rm -rf "$extract_dir"; error "Failed to extract AppImage"; return 1; }

  local root="${extract_dir}/squashfs-root"
  local app_dir="${XDG_DATA_HOME}/applications"
  local icon_dir="${XDG_DATA_HOME}/icons/hicolor/256x256/apps"
  install -d "$app_dir" "$icon_dir"

  local desktop_file="${root}/${desktop_id}.desktop"
  [[ -f "$desktop_file" ]] || { rm -rf "$extract_dir"; error "Desktop file not found: ${desktop_id}.desktop"; return 1; }

  # Find icon — try common extensions
  local icon_file=""
  local ext
  for ext in png svg; do
    icon_file="$(find -L "$root" -maxdepth 1 -name "${desktop_id}.${ext}" | head -n1)"
    [[ -n "$icon_file" ]] && break
  done
  [[ -n "$icon_file" ]] || { rm -rf "$extract_dir"; error "Icon not found for ${desktop_id}"; return 1; }

  local icon_basename
  icon_basename="$(basename "$icon_file")"

  install -m 0644 "$desktop_file" "${app_dir}/${desktop_id}.desktop"
  install -m 0644 "$icon_file" "${icon_dir}/${icon_basename}"

  # Normalize desktop entry: remove TryExec, point Exec to stable wrapper
  sed -i '/^TryExec=/d' "${app_dir}/${desktop_id}.desktop"
  sed -i "s|^Exec=.*\$|Exec=${exec_line}|g" "${app_dir}/${desktop_id}.desktop"

  rm -rf "$extract_dir"

  command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$app_dir" || true
  command -v gtk-update-icon-cache >/dev/null 2>&1 && gtk-update-icon-cache -f -t "${XDG_DATA_HOME}/icons/hicolor" || true
}

# tool_appimage_uninstall_desktop <desktop_id> [icon_ext]
#
# Removes the .desktop file and icon installed by tool_appimage_desktop.
# icon_ext defaults to "png".
tool_appimage_uninstall_desktop() {
  local desktop_id="$1"
  local icon_ext="${2:-png}"
  rm -f "${XDG_DATA_HOME}/applications/${desktop_id}.desktop"
  rm -f "${XDG_DATA_HOME}/icons/hicolor/256x256/apps/${desktop_id}.${icon_ext}"
  command -v update-desktop-database >/dev/null 2>&1 \
    && update-desktop-database "${XDG_DATA_HOME:-$HOME/.local/share}/applications" || true
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
# Recipe variables:
#   TOOL_CMD                     — (required) binary name for command -v check
#   TOOL_REPO                    — GitHub owner/repo (triggers gh-release flow)
#   TOOL_ASSET_MACOS_ARM64       — asset glob for macOS ARM64
#   TOOL_ASSET_LINUX_ARM64       — asset glob for Linux ARM64
#   TOOL_ASSET_LINUX_AMD64       — asset glob for Linux x86_64
#   TOOL_LINKS                   — array of symlink specs: "src:dst" or bare "name" (→ name:bin/name)
#   TOOL_MAN_PAGES               — array of man page paths to link (relative to install dir)
#   TOOL_COMPLETIONS             — array of completion specs: "src:dst" or bare path (→ basename as dst)
#   TOOL_STRIP_COMPONENTS        — strip N leading directory components during extraction (like tar --strip-components)
#
# Recipe hook functions (optional — override default behavior):
#   tool_download         — default: tool_gh_install using TOOL_REPO + resolved asset
#   tool_post_install     — default: create symlinks from TOOL_LINKS/TOOL_MAN_PAGES/TOOL_COMPLETIONS
#   tool_platform_check   — default: allow all platforms
#   tool_externally_managed — default: false; when true and batch skip is enabled, recipe is skipped
#   tool_upgrade          — default: re-run tool_download (use for tools with self-update commands)
#
# Driver flow:
#   1. Source recipe (sets vars, optionally defines hooks)
#   2. tool_check $TOOL_CMD           — skip if already installed (unless upgrade)
#   3. tool_platform_check            — bail with guidance if unsupported
#   4. tool_download                  — default: tool_gh_install
#   5. tool_post_install              — default: symlink TOOL_LINKS
#   6. Log completion

# Canonical platform key for asset resolution.
# Maps TOOLS_PLATFORM (aarch64-darwin, etc.) to recipe-friendly names.
_tool_platform_key() {
  case "$TOOLS_PLATFORM" in
    aarch64-darwin) printf 'MACOS_ARM64'  ;;
    aarch64-linux)  printf 'LINUX_ARM64'  ;;
    x86_64-linux)   printf 'LINUX_AMD64'  ;;
    *)              printf 'UNKNOWN'      ;;
  esac
}

# _tool_resolve_asset
# Resolves the asset glob for the current platform from TOOL_ASSET_* variables.
_tool_resolve_asset() {
  local key
  key="$(_tool_platform_key)"
  local var="TOOL_ASSET_${key}"
  printf '%s' "${!var:-}"
}

# _tool_default_post_install
# Creates symlinks from TOOL_LINKS, TOOL_MAN_PAGES, and TOOL_COMPLETIONS arrays.
# Errors if a declared path does not exist (indicates archive layout changed).
_tool_default_post_install() {
  local spec src dst src_path
  for spec in "${TOOL_LINKS[@]:-}"; do
    [[ -n "$spec" ]] || continue
    if [[ "$spec" == *:* ]]; then
      src="${spec%%:*}"
      dst="${spec#*:}"
    else
      src="$spec"
      dst="bin/${spec}"
    fi
    src_path="${TOOLS_INSTALL_DIR}/${src}"
    [[ -e "$src_path" ]] || { error "tool_post_install: expected path not found: ${src_path}"; return 1; }
    tool_link "$src" "$dst"
  done

  local page page_path
  for page in "${TOOL_MAN_PAGES[@]:-}"; do
    [[ -n "$page" ]] || continue
    page_path="${TOOLS_INSTALL_DIR}/${page}"
    [[ -e "$page_path" ]] || { error "tool_post_install: expected man page not found: ${page_path}"; return 1; }
    local basename_page
    basename_page="$(basename "$page")"
    local section="${basename_page##*.}"
    tool_link "$page" "share/man/man${section}/${basename_page}"
  done

  local comp comp_path
  for comp in "${TOOL_COMPLETIONS[@]:-}"; do
    [[ -n "$comp" ]] || continue
    local comp_src comp_dst
    if [[ "$comp" == *:* ]]; then
      comp_src="${comp%%:*}"
      comp_dst="${comp#*:}"
    else
      comp_src="$comp"
      comp_dst="$(basename "$comp")"
    fi
    comp_path="${TOOLS_INSTALL_DIR}/${comp_src}"
    [[ -e "$comp_path" ]] || { error "tool_post_install: expected completion not found: ${comp_path}"; return 1; }
    tool_link "$comp_src" "share/completions/${comp_dst}"
  done

  # Prune stale completion symlinks that point into this tool's cellar
  # but are not part of the current recipe (e.g. after removing bash completions).
  local comp_dir="${XDG_OPT_HOME}/share/completions"
  if [[ -d "$comp_dir" ]] && [[ -n "${TOOL_REPO:-}" ]]; then
    local cellar_prefix="${TOOLS_CELLAR}/${TOOL_REPO##*/}/"
    local link target
    find "$comp_dir" -maxdepth 1 -type l | while IFS= read -r link; do
      target="$(readlink "$link" 2>/dev/null)" || continue
      [[ "$target" == "$cellar_prefix"* ]] || continue
      local base
      base="$(basename "$link")"
      local declared=0
      for comp in "${TOOL_COMPLETIONS[@]:-}"; do
        [[ -n "$comp" ]] || continue
        local chk_dst
        if [[ "$comp" == *:* ]]; then chk_dst="${comp#*:}"; else chk_dst="$(basename "$comp")"; fi
        [[ "$base" == "$chk_dst" ]] && declared=1 && break
      done
      if [[ "$declared" -eq 0 ]]; then
        rm -f "$link"
        vlog "prune" "stale completion: $link"
      fi
    done
  fi
}

_tool_ready_path() {
  local resolved
  resolved="$(command -v "$TOOL_CMD" 2>/dev/null || true)"
  if [[ -n "$resolved" ]]; then
    printf '%s\n' "$resolved"
  else
    printf '%s\n' "${TOOLS_BIN}/${TOOL_CMD}"
  fi
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
  unset TOOL_CMD TOOL_REPO TOOL_BREW TOOL_LINKS TOOL_MAN_PAGES TOOL_COMPLETIONS
  unset TOOL_STRIP_COMPONENTS TOOL_VERSION_ARGS
  unset TOOL_ASSET_MACOS_ARM64
  unset TOOL_ASSET_LINUX_ARM64 TOOL_ASSET_LINUX_AMD64
  unset -f tool_download tool_post_install tool_platform_check tool_externally_managed tool_upgrade 2>/dev/null

  # Source the recipe — sets vars and optionally defines hooks
  source "$recipe"

  [[ -n "${TOOL_CMD:-}" ]] || { error "tool_run_recipe: TOOL_CMD not set in ${recipe}"; return 1; }

  if [[ -n "${DOTFILES_TOOL_SKIP_EXTERNAL:-}" ]] && declare -f tool_externally_managed >/dev/null 2>&1; then
    if tool_externally_managed; then
      TOOLS_INSTALL_SKIPPED=1
      TOOLS_INSTALL_SKIPPED_REASON="external"
      vlog "skip" "$(basename "$recipe" .sh) externally managed on $(uname -s)"
      return 0
    fi
  fi

  # 1. Skip if already installed (unless upgrading)
  tool_check "$TOOL_CMD" || return 0

  # 2. Platform check (hook or default pass-through)
  if declare -f tool_platform_check >/dev/null 2>&1; then
    tool_platform_check
  fi

  # 3. If upgrading and a tool_upgrade hook exists, use it instead of the normal flow
  if [[ -n "${DOTFILES_TOOL_UPGRADE:-}" ]] && declare -f tool_upgrade >/dev/null 2>&1; then
    log "upgrade" "$TOOL_CMD"
    tool_upgrade
    return $?
  fi

  # 4. Download (hook or default gh-release)
  if declare -f tool_download >/dev/null 2>&1; then
    tool_download
  elif [[ -n "${TOOL_REPO:-}" ]]; then
    local asset
    asset="$(_tool_resolve_asset)"
    if [[ -z "$asset" ]]; then
      error "tool_run_recipe: no asset for platform ${TOOLS_PLATFORM} in ${recipe}"
      return 1
    fi
    tool_gh_install "$TOOL_REPO" "$asset"
  else
    error "tool_run_recipe: TOOL_REPO not set and no tool_download hook in ${recipe}"
    return 1
  fi

  # 4. Nothing to do if download determined we're already current
  if [[ "${TOOLS_INSTALL_SKIPPED:-0}" -eq 1 ]]; then
    return 0
  fi

  # 5. Post-install (hook or default symlinks)
  if declare -f tool_post_install >/dev/null 2>&1; then
    tool_post_install
  else
    _tool_default_post_install
  fi

  # 6. Log completion
  log "ready" "${TOOL_CMD} installed: $(_tool_ready_path)"
}
