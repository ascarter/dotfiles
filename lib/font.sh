# lib/font.sh — font subcommand implementation for bin/dotfiles
#
# Sourced on demand by cmd_font in bin/dotfiles.
# Inherits log/warn/abort/vlog/error and tty_* variables from the caller.
#
# No shebang — this file is sourced, not executed.

# Idempotent guard
[[ -n "${_DOTFILES_FONT_LOADED:-}" ]] && return 0
_DOTFILES_FONT_LOADED=1

# ---------------------------------------------------------------------------
# Platform helpers
# ---------------------------------------------------------------------------

# font_os_dir
# Returns the platform-specific user font directory.
font_os_dir() {
  case "$(uname -s)" in
    Darwin) printf '%s/Library/Fonts' "$HOME" ;;
    Linux)  printf '%s/.local/share/fonts' "$HOME" ;;
    *)      abort "unsupported platform for font installation" ;;
  esac
}

# font_cache_refresh
# Refreshes the system font cache on Linux. No-op on macOS (automatic).
font_cache_refresh() {
  case "$(uname -s)" in
    Linux)
      if command -v fc-cache >/dev/null 2>&1; then
        log "fonts" "refreshing font cache"
        fc-cache -f "$(font_os_dir)" 2>/dev/null || true
      fi
      ;;
  esac
}

# ---------------------------------------------------------------------------
# Font install primitives
# ---------------------------------------------------------------------------

# font_install_files <cellar-dir> [font-glob]
#
# Finds font files matching the glob pattern in the cellar directory and
# copies them flat into the OS font directory.
# Default glob: *.ttf (flat TTF files in the cellar root).
# Uses find -path for robust handling of spaces in directory names.
font_install_files() {
  local cellar_dir="$1"
  local font_glob="${2:-*.ttf}"
  local font_dir
  font_dir="$(font_os_dir)"
  mkdir -p "$font_dir"

  local count=0
  while IFS= read -r -d '' f; do
    cp -f "${cellar_dir}/${f#./}" "$font_dir/"
    count=$((count + 1))
  done < <(cd "$cellar_dir" && find . -type f -path "./$font_glob" -print0 2>/dev/null)

  if [[ "$count" -eq 0 ]]; then
    error "no font files matching '${font_glob}' found in ${cellar_dir}"
    return 1
  fi

  log "fonts" "copied ${count} file(s) to ${font_dir}"
  font_cache_refresh
}

# font_gh_install <name> <owner/repo> <asset-glob> [tag]
#
# Downloads and extracts a GitHub release asset for a font.
# Uses explicit <name> for cellar/cache/state paths (unlike tool_gh_install
# which derives the name from the repo).
#
# After completion, sets:
#   TOOLS_INSTALL_DIR     — versioned install directory
#   TOOLS_INSTALL_TAG     — raw release tag (for GitHub API calls)
#   TOOLS_INSTALL_VERSION — normalized version
font_gh_install() {
  local name="$1"
  local repo="$2"
  local asset_glob="$3"
  local tag="${4:-}"
  local state_file="${TOOLS_STATE}/${name}"

  # Resolve tag — prefer recipe hook, fall back to tool_latest_tag
  if [[ -z "$tag" ]]; then
    if declare -f font_latest_tag >/dev/null 2>&1; then
      tag="$(font_latest_tag)" || { error "font_gh_install: failed to resolve tag for ${name}"; return 1; }
    else
      tag="$(tool_latest_tag "$repo")" || { error "font_gh_install: failed to resolve tag for ${repo}"; return 1; }
    fi
  fi

  if [[ -z "$tag" ]]; then
    error "font_gh_install: could not determine tag for ${name}"
    return 1
  fi

  local version
  version="$(_tool_normalize_version "$tag")" || return 1

  TOOLS_INSTALL_DIR="${TOOLS_CELLAR}/${name}/${version}"
  TOOLS_INSTALL_TAG="$tag"
  TOOLS_INSTALL_VERSION="$version"
  export TOOLS_INSTALL_DIR TOOLS_INSTALL_TAG TOOLS_INSTALL_VERSION

  # Skip if already installed at this version
  local installed_version="none"
  if [[ -f "$state_file" ]]; then
    installed_version="$(cat "$state_file")"
  fi
  if [[ "$installed_version" == "$version" && -d "$TOOLS_INSTALL_DIR" ]]; then
    vlog "skip" "${name} at ${version}"
    TOOLS_INSTALL_SKIPPED=1
    return 0
  fi

  local cache_dir="${TOOLS_CACHE}/${name}"
  mkdir -p "$cache_dir" "$TOOLS_INSTALL_DIR"

  log "download" "${name} ${tag}"
  gh release download "$tag" \
    --repo "$repo" \
    --pattern "$asset_glob" \
    --dir "$cache_dir" \
    --clobber || { error "font_gh_install: download failed for ${name} ${tag}"; return 1; }

  # Find the downloaded file
  local asset_file
  asset_file="$(find "$cache_dir" -maxdepth 1 -name "$asset_glob" | head -n1)"
  if [[ -z "$asset_file" ]]; then
    error "font_gh_install: no asset matching ${asset_glob} found in ${cache_dir}"
    return 1
  fi

  # Extract based on format
  local filename
  filename="$(basename "$asset_file")"

  if [[ "$filename" == *.tar.gz || "$filename" == *.tgz ]]; then
    tar -xzf "$asset_file" -C "$TOOLS_INSTALL_DIR" \
      --strip-components="${FONT_STRIP_COMPONENTS:-0}" \
      || { error "font_gh_install: extraction failed"; return 1; }
  elif [[ "$filename" == *.zip ]]; then
    unzip -q -o "$asset_file" -d "$TOOLS_INSTALL_DIR" \
      || { error "font_gh_install: extraction failed"; return 1; }
    # Strip leading directory from zip if requested
    if [[ -n "${FONT_STRIP_COMPONENTS:-}" && "${FONT_STRIP_COMPONENTS:-0}" -gt 0 ]]; then
      local nested_dir
      nested_dir="$(find "$TOOLS_INSTALL_DIR" -mindepth 1 -maxdepth 1 -type d | head -n1)"
      if [[ -n "$nested_dir" ]]; then
        mv "$nested_dir"/* "$TOOLS_INSTALL_DIR"/ 2>/dev/null || true
        rmdir "$nested_dir" 2>/dev/null || true
      fi
    fi
  else
    error "font_gh_install: unsupported archive format: ${filename}"
    return 1
  fi

  printf '%s\n' "$version" > "$state_file"
  log "install" "${name} ${version} -> ${TOOLS_INSTALL_DIR}"
}

# ---------------------------------------------------------------------------
# Declarative font recipe driver
# ---------------------------------------------------------------------------
#
# Recipes are pure config files in fonts/ (no shebang).
# The driver sources a recipe to load its variables and optional hooks,
# then executes the standard install flow.
#
# Recipe variables:
#   FONT_REPO              — GitHub owner/repo
#   FONT_ASSET             — release asset glob pattern
#   FONT_GLOB              — glob to find TTF files within cellar (default: *.ttf)
#   FONT_STRIP_COMPONENTS  — strip N leading dirs during extraction
#
# Recipe hook functions (optional):
#   font_latest_tag     — override tag resolution (e.g. IBM Plex NPM-style tags)
#   font_download       — override download entirely (e.g. non-GitHub source)
#   font_post_install   — override file copy (default: font_install_files)
#
# Driver flow:
#   1. Source recipe (sets vars, optionally defines hooks)
#   2. font_download (hook or default font_gh_install)
#   3. Skip if already at latest tag
#   4. font_post_install (hook or default: copy TTFs to OS font dir)
#   5. Log completion

font_run_recipe() {
  local recipe="$1"

  [[ -f "$recipe" ]] || { error "font_run_recipe: not found: ${recipe}"; return 1; }

  # Reset recipe state
  TOOLS_INSTALL_SKIPPED=0
  unset FONT_REPO FONT_ASSET FONT_GLOB FONT_STRIP_COMPONENTS TOOL_VERSION_MATCH
  unset -f font_download font_post_install font_latest_tag 2>/dev/null

  source "$recipe"

  local name
  name="$(basename "$recipe" .sh)"

  # 1. Download (hook or default gh-release)
  if declare -f font_download >/dev/null 2>&1; then
    font_download
  elif [[ -n "${FONT_REPO:-}" ]]; then
    local asset="${FONT_ASSET:-}"
    if [[ -z "$asset" ]]; then
      error "font_run_recipe: FONT_ASSET not set in ${recipe}"
      return 1
    fi
    font_gh_install "$name" "$FONT_REPO" "$asset"
  else
    error "font_run_recipe: FONT_REPO not set and no font_download hook in ${recipe}"
    return 1
  fi

  # 2. Skip if already current
  if [[ "${TOOLS_INSTALL_SKIPPED:-0}" -eq 1 ]]; then
    return 0
  fi

  # 3. Post-install (hook or default: copy TTFs to font dir)
  if declare -f font_post_install >/dev/null 2>&1; then
    font_post_install
  else
    font_install_files "$TOOLS_INSTALL_DIR" "${FONT_GLOB:-*.ttf}"
  fi

  log "ready" "${name} installed"
}

# ---------------------------------------------------------------------------
# Subcommands
# ---------------------------------------------------------------------------

_font_ensure_gh() {
  if ! command -v gh >/dev/null 2>&1; then
    # Try to bootstrap via the tool system
    source "${DOTFILES_HOME}/lib/tool.sh"
    _tool_bootstrap_gh || abort "gh is required for font management and could not be bootstrapped"
  fi
}

# _font_install [<name>]
_font_install() {
  local target="${1:-}"
  local fonts_dir="${DOTFILES_HOME}/fonts"

  _font_ensure_gh
  [[ -d "$fonts_dir" ]] || abort "fonts directory not found: $fonts_dir"
  source "${DOTFILES_HOME}/lib/opt.sh"

  if [[ -n "$target" ]]; then
    local script="${fonts_dir}/${target}.sh"
    [[ -f "$script" ]] || abort "Unknown font: $target"
    font_run_recipe "$script"
  else
    local failed=0
    while IFS= read -r script; do
      font_run_recipe "$script" || {
        warn "$(basename "$script" .sh)" "installation failed"
        failed=1
      }
    done < <(find "$fonts_dir" -maxdepth 1 -name "*.sh" | sort)
    return $failed
  fi
}

# _font_list
_font_list() {
  local fonts_dir="${DOTFILES_HOME}/fonts"
  [[ -d "$fonts_dir" ]] || abort "fonts directory not found: $fonts_dir"
  source "${DOTFILES_HOME}/lib/opt.sh"

  local -a names=() tags=()
  while IFS= read -r script; do
    local name
    name="$(basename "$script" .sh)"
    local state_file="${TOOLS_STATE}/${name}"
    if [[ -f "$state_file" ]]; then
      names+=("$name")
      tags+=("$(cat "$state_file")")
    fi
  done < <(find "$fonts_dir" -maxdepth 1 -name "*.sh" 2>/dev/null | sort)

  if [[ ${#names[@]} -eq 0 ]]; then
    printf "  no fonts installed\n"
    return 0
  fi

  # Compute column widths
  local w_name=4 w_tag=7
  for i in "${!names[@]}"; do
    [[ ${#names[$i]} -gt $w_name ]] && w_name=${#names[$i]}
    [[ ${#tags[$i]} -gt $w_tag ]] && w_tag=${#tags[$i]}
  done

  local sep_name sep_tag
  sep_name="$(printf '─%.0s' $(seq 1 $w_name))"
  sep_tag="$(printf '─%.0s' $(seq 1 $w_tag))"

  printf "  ${tty_bold}%-${w_name}s  %s${tty_reset}\n" "FONT" "VERSION"
  printf "  %-${w_name}s  %s\n" "$sep_name" "$sep_tag"
  for i in "${!names[@]}"; do
    printf "  %-${w_name}s  %s\n" "${names[$i]}" "${tags[$i]}"
  done

  printf "\n  %d font%s installed\n" "${#names[@]}" "$([[ ${#names[@]} -eq 1 ]] && printf '' || printf 's')"
}

# _font_cmd <op> [<name>]
# Main dispatcher — called by cmd_font in bin/dotfiles.
_font_cmd() {
  local op="${1:-}"
  shift 2>/dev/null || true

  [[ -n "${DOTFILES_HOME:-}" ]] || abort "DOTFILES_HOME is not set"

  case "$op" in
    install) _font_install "$@" ;;
    list)    _font_list ;;
    "")
      abort "usage: dotfiles font <install|list> [<fontname>]"
      ;;
    *)
      abort "unknown font operation: $op (use install or list)"
      ;;
  esac
}
