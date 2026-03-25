# lib/opt/github.sh — GitHub release driver
#
# Provides primitives for downloading and installing tools from GitHub releases.
# Sourced by lib/opt.sh — do not source directly.
#
# Public functions:
#   tool_latest_tag       — resolve latest stable release tag
#   tool_installed_tag    — read installed tag from state file
#   tool_gh_install       — download + extract a GitHub release asset
#   tool_strip_quarantine — strip macOS quarantine attribute
#
# Driver helpers (called by tool_run_recipe):
#   _tool_platform_key    — map platform to TOOL_ASSET_* key
#   _tool_resolve_asset   — resolve asset glob for current platform
#   _tool_default_post_install — symlink TOOL_LINKS, TOOL_MAN_PAGES, TOOL_COMPLETIONS
#
# No shebang — this file is sourced, not executed.

# tool_latest_tag <owner/repo>
# Prints the latest stable (non-draft, non-prerelease) release tag for the given repo.
tool_latest_tag() {
  local repo="$1"
  gh release list --repo "$repo" --limit 100 \
    --json tagName,isLatest,isPrerelease,isDraft \
    --jq 'map(select((.isDraft | not) and (.isPrerelease | not))) | (map(select(.isLatest == true))[0].tagName // .[0].tagName // empty)'
}

# tool_installed_tag <owner/repo>
# Reads the installed version from the state file. Prints version or "none".
# Uses TOOLS_NAME (script basename) when set, falls back to repo basename.
tool_installed_tag() {
  local repo="$1"
  local name="${TOOLS_NAME:-${repo##*/}}"
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
#   TOOLS_INSTALL_DIR     — versioned install directory (TOOLS_CELLAR/<name>/<version>/)
#   TOOLS_INSTALL_TAG     — raw release tag (for GitHub API calls)
#   TOOLS_INSTALL_VERSION — normalized version (for display and state)
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
  local name="${TOOLS_NAME:-${repo##*/}}"
  local state_file="${TOOLS_STATE}/${name}"

  # Resolve tag if not provided. Default is the latest stable release.
  if [[ -z "$tag" ]]; then
    tag="$(tool_latest_tag "$repo")" || { error "tool_gh_install: failed to resolve tag for ${repo}"; return 1; }
  fi

  if [[ -z "$tag" ]]; then
    error "tool_gh_install: could not determine tag for ${repo}"
    return 1
  fi

  local version
  version="$(_tool_normalize_version "$tag")" || return 1

  TOOLS_INSTALL_DIR="${TOOLS_CELLAR}/${name}/${version}"
  TOOLS_INSTALL_TAG="$tag"
  TOOLS_INSTALL_VERSION="$version"
  export TOOLS_INSTALL_DIR TOOLS_INSTALL_TAG TOOLS_INSTALL_VERSION

  # Skip if already installed at this version
  local installed_version
  installed_version="$(tool_installed_tag "$repo")"
  if [[ "$installed_version" == "$version" && -d "$TOOLS_INSTALL_DIR" ]]; then
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

  # Record installed version (normalized)
  printf '%s\n' "$version" > "$state_file"
  log "install" "${name} ${version} -> ${TOOLS_INSTALL_DIR}"
}

# _tool_download_extras
# Downloads and extracts TOOL_ASSET_EXTRA entries into TOOLS_INSTALL_DIR.
# Called after tool_gh_install when the array is set. Uses TOOLS_INSTALL_TAG
# and TOOL_REPO set by the prior download step.
_tool_download_extras() {
  local extra cache_dir asset_file filename
  cache_dir="${TOOLS_CACHE}/${TOOLS_NAME:-${TOOL_REPO##*/}}"
  for extra in "${TOOL_ASSET_EXTRA[@]:-}"; do
    [[ -n "$extra" ]] || continue
    gh release download "$TOOLS_INSTALL_TAG" \
      --repo "$TOOL_REPO" \
      --pattern "$extra" \
      --dir "$cache_dir" \
      --clobber || { error "extra asset download failed: ${extra}"; return 1; }
    asset_file="$(find "$cache_dir" -maxdepth 1 -name "$extra" | head -n1)"
    [[ -n "$asset_file" ]] || { error "extra asset not found: ${extra}"; return 1; }
    filename="$(basename "$asset_file")"
    if [[ "$filename" == *.tar.gz || "$filename" == *.tgz ]]; then
      tar -xzf "$asset_file" -C "$TOOLS_INSTALL_DIR"
    elif [[ "$filename" == *.zip ]]; then
      unzip -q -o "$asset_file" -d "$TOOLS_INSTALL_DIR"
    else
      cp "$asset_file" "${TOOLS_INSTALL_DIR}/${filename}"
    fi
  done
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

# ---------------------------------------------------------------------------
# Asset resolution and default post-install (used by tool_run_recipe)
# ---------------------------------------------------------------------------

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
    # Bare binary fallback: if the expected path doesn't exist and there's
    # exactly one file in the install dir, use it (handles platform-named
    # binaries like jq-linux-amd64 or yq_darwin_arm64).
    if [[ ! -e "$src_path" ]]; then
      local -a files=()
      while IFS= read -r f; do files+=("$f"); done < <(find "$TOOLS_INSTALL_DIR" -maxdepth 1 -type f)
      if [[ ${#files[@]} -eq 1 ]]; then
        src="$(basename "${files[0]}")"
        src_path="${files[0]}"
      else
        error "tool_post_install: expected path not found: ${src_path}"
        return 1
      fi
    fi
    tool_link "$src" "$dst"
  done

  local page page_path
  for page in "${TOOL_MAN_PAGES[@]:-}"; do
    [[ -n "$page" ]] || continue
    page_path="${TOOLS_INSTALL_DIR}/${page}"
    [[ -e "$page_path" ]] || { error "tool_post_install: expected man page not found: ${page_path}"; return 1; }
    local basename_page
    basename_page="$(basename "$page")"
    # Handle .gz man pages: btm.1.gz → section 1, keep .gz filename
    local section_name="$basename_page"
    [[ "$section_name" != *.gz ]] || section_name="${section_name%.gz}"
    local section="${section_name##*.}"
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
    local cellar_prefix="${TOOLS_CELLAR}/${TOOLS_NAME:-${TOOL_REPO##*/}}/"
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
