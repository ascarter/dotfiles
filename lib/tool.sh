# lib/tool.sh — tool subcommand implementation for bin/dotfiles
#
# Sourced on demand by cmd_tool and cmd_status in bin/dotfiles.
# Inherits log/warn/abort/vlog/error and tty_* variables from the caller.
#
# No shebang — this file is sourced, not executed.

# Idempotent guard
[[ -n "${_DOTFILES_TOOL_LOADED:-}" ]] && return 0
_DOTFILES_TOOL_LOADED=1

# _tool_prune_symlinks <dir>
# Remove broken symlinks under <dir> (up to 3 levels deep).
_tool_prune_symlinks() {
  local dir="$1"
  [[ -d "$dir" ]] || return 0
  find "$dir" -maxdepth 3 -type l | while IFS= read -r link; do
    if [[ ! -e "$link" ]]; then
      rm -f "$link"
      log "prune" "$link"
    fi
  done
}

# _tool_status
# Show the state of the opt packaging infrastructure.
_tool_status() {
  source "${DOTFILES_HOME}/lib/opt.sh"
  local tools_dir="${DOTFILES_HOME}/tools"

  printf "  ${tty_bold}Paths${tty_reset}\n"
  printf "  %-12s %s\n" "opt home:" "$XDG_OPT_HOME"
  printf "  %-12s %s\n" "bin:" "$XDG_OPT_BIN"
  printf "  %-12s %s\n" "share:" "$XDG_OPT_SHARE"
  printf "  %-12s %s\n" "cellar:" "$TOOLS_CELLAR"
  printf "  %-12s %s\n" "cache:" "$TOOLS_CACHE"
  printf "  %-12s %s\n" "state:" "$TOOLS_STATE"

  local scripts=0 installed=0 external=0
  if [[ -d "$tools_dir" ]]; then
    scripts="$(find "$tools_dir" -maxdepth 1 -name "*.sh" 2>/dev/null | wc -l | tr -d ' ')"
  fi
  if [[ -d "$TOOLS_STATE" ]]; then
    installed="$(find "$TOOLS_STATE" -maxdepth 1 -type f 2>/dev/null | wc -l | tr -d ' ')"
  fi
  if [[ -d "$tools_dir" ]]; then
    while IFS= read -r script; do
      local name cmd
      name="$(basename "$script" .sh)"
      cmd="$(_tool_cmd_name "$script")"
      if [[ ! -f "${TOOLS_STATE}/${name}" ]] && command -v "$cmd" >/dev/null 2>&1; then
        external=$((external + 1))
      fi
    done < <(find "$tools_dir" -maxdepth 1 -name "*.sh" 2>/dev/null | sort)
  fi

  printf "\n  ${tty_bold}Summary${tty_reset}\n"
  printf "  %-12s %s\n" "available:" "$scripts"
  printf "  %-12s %s\n" "installed:" "$installed"
  printf "  %-12s %s\n" "external:" "$external"

  if [[ -d "$XDG_OPT_HOME" ]]; then
    local size
    size="$(du -sh "$XDG_OPT_HOME" 2>/dev/null | cut -f1 | tr -d ' ')"
    printf "  %-12s %s\n" "disk:" "$size"
  fi
}

# _tool_bootstrap_gh
# Auto-install gh via its curl-based recipe when gh is not found.
# Returns 0 on success, 1 on failure.
_tool_bootstrap_gh() {
  local tools_dir="${DOTFILES_HOME}/tools"
  local gh_script="${tools_dir}/gh.sh"
  [[ -f "$gh_script" ]] || { error "gh recipe not found: ${gh_script}"; return 1; }

  log "bootstrap" "installing gh (GitHub CLI) via curl"
  source "${DOTFILES_HOME}/lib/opt.sh"
  tool_run_recipe "$gh_script" || { error "gh bootstrap failed"; return 1; }

  # Ensure the freshly installed gh is on PATH for this session
  export PATH="${XDG_OPT_BIN}:${PATH}"
  if ! command -v gh >/dev/null 2>&1; then
    error "gh not found after bootstrap install"
    return 1
  fi

  log "bootstrap" "gh installed successfully"
  log "hint" "run 'dotfiles gitconfig' to configure GitHub authentication and git identity"
}

# _tool_ensure_gh
# Ensures gh is available, bootstrapping it if necessary.
_tool_ensure_gh() {
  command -v gh >/dev/null 2>&1 && return 0
  _tool_bootstrap_gh
}

# _tool_install [<name>]
_tool_install() {
  local target="${1:-}"
  local tools_dir="${DOTFILES_HOME}/tools"

  _tool_ensure_gh || abort "gh is required for tool management and could not be bootstrapped"
  [[ -d "$tools_dir" ]] || abort "tools directory not found: $tools_dir"
  source "${DOTFILES_HOME}/lib/opt.sh"

  if [[ -n "$target" ]]; then
    local script="${tools_dir}/${target}.sh"
    [[ -f "$script" ]] || abort "Unknown tool: $target"
    vlog "tool" "install $target"
    if tool_is_recipe "$script"; then
      tool_run_recipe "$script"
    else
      bash "$script"
    fi
  else
    local failed=0
    export DOTFILES_TOOL_SKIP_EXTERNAL=1
    while IFS= read -r script; do
      local tool_name
      tool_name="$(basename "$script" .sh)"
      # Skip gh — already bootstrapped above
      [[ "$tool_name" != "gh" ]] || continue
      vlog "tool" "install $tool_name"
      if tool_is_recipe "$script"; then
        tool_run_recipe "$script" || {
          warn "$tool_name" "installation failed"
          failed=1
        }
      else
        bash "$script" || {
          warn "$tool_name" "installation failed"
          failed=1
        }
      fi
    done < <(find "$tools_dir" -maxdepth 1 -name "*.sh" | sort)
    unset DOTFILES_TOOL_SKIP_EXTERNAL
    return $failed
  fi
}

# _tool_run_uninstall_hook <name> <force>
# Source the tool recipe and call tool_uninstall hook if defined.
# In force mode, hook failures warn instead of aborting.
_tool_run_uninstall_hook() {
  local name="$1"
  local force="$2"
  local tools_dir="${DOTFILES_HOME}/tools"
  local script="${tools_dir}/${name}.sh"

  [[ -f "$script" ]] || return 0

  # Reset recipe state before sourcing
  unset TOOL_CMD TOOL_TYPE TOOL_REPO TOOL_BREW TOOL_LINKS TOOL_MAN_PAGES TOOL_COMPLETIONS
  unset TOOL_STRIP_COMPONENTS TOOL_VERSION_ARGS TOOL_VERSION_MATCH
  unset TOOL_ASSET_MACOS_ARM64
  unset TOOL_ASSET_LINUX_ARM64 TOOL_ASSET_LINUX_AMD64
  unset TOOL_DESKTOP_ID TOOL_DESKTOP_EXEC TOOL_DESKTOP_ICON_EXT TOOL_APPIMAGE_GLOB
  unset TOOL_INSTALL_URL TOOL_INSTALL_ENV TOOL_INSTALL_ARGS
  unset -f tool_download tool_post_install tool_platform_check tool_externally_managed tool_uninstall 2>/dev/null

  source "$script"

  if declare -f tool_uninstall >/dev/null 2>&1; then
    log "uninstall" "running hook for $name"
    if [[ "$force" -eq 1 ]]; then
      tool_uninstall || warn "$name" "uninstall hook failed (continuing with --force)"
    else
      tool_uninstall || { error "uninstall hook failed for $name"; return 1; }
    fi
  elif [[ "${TOOL_TYPE:-}" == "appimage" && -n "${TOOL_DESKTOP_ID:-}" ]]; then
    log "uninstall" "removing desktop integration for $name"
    source "${DOTFILES_HOME}/lib/opt.sh"
    tool_appimage_uninstall_desktop "$TOOL_DESKTOP_ID" "${TOOL_DESKTOP_ICON_EXT:-png}"
  elif [[ "${TOOL_TYPE:-}" == "installer" && -n "${TOOL_CMD:-}" ]]; then
    local cmd_path
    cmd_path="$(command -v "$TOOL_CMD" 2>/dev/null || true)"
    if [[ -n "$cmd_path" ]]; then
      log "uninstall" "removing $cmd_path"
      rm -f "$cmd_path"
    fi
  fi
}

# _tool_uninstall [--force] [<name>]
_tool_uninstall() {
  local force=0
  local target=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --force) force=1; shift ;;
      *)       target="$1"; shift ;;
    esac
  done

  source "${DOTFILES_HOME}/lib/opt.sh"

  if [[ -n "$target" ]]; then
    local install_dir="${TOOLS_CELLAR}/${target}"
    if [[ "$force" -eq 0 && ! -d "$install_dir" ]]; then
      # Allow installer-type tools and tools with uninstall hooks to skip cellar check
      local script="${DOTFILES_HOME}/tools/${target}.sh"
      if [[ -f "$script" ]]; then
        if ! grep -q 'tool_uninstall()' "$script" && ! grep -q 'TOOL_TYPE=installer' "$script"; then
          abort "$target is not installed in cellar (use --force to clean up broken installs)"
        fi
      else
        abort "$target is not installed in cellar (use --force to clean up broken installs)"
      fi
    fi
    _tool_run_uninstall_hook "$target" "$force"
    if [[ -d "$install_dir" ]]; then
      rm -rf "$install_dir"
      log "uninstall" "$target"
    fi
    rm -f "${TOOLS_STATE}/${target}"
  else
    if [[ "$force" -eq 1 ]]; then
      # Force-uninstall all: run hooks for every tool with a recipe
      local tools_dir="${DOTFILES_HOME}/tools"
      if [[ -d "$tools_dir" ]]; then
        while IFS= read -r script; do
          local name
          name="$(basename "$script" .sh)"
          _tool_run_uninstall_hook "$name" "$force"
        done < <(find "$tools_dir" -maxdepth 1 -name "*.sh" 2>/dev/null | sort)
      fi
    fi
    local removed=0
    while IFS= read -r d; do
      rm -rf "$d"
      log "uninstall" "$(basename "$d")"
      removed=1
    done < <(find "$TOOLS_CELLAR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
    find "$TOOLS_STATE" -maxdepth 1 -type f -delete 2>/dev/null || true
    [[ "$removed" -eq 1 ]] || log "uninstall" "nothing installed"
  fi
  _tool_prune_symlinks "$TOOLS_BIN"
  _tool_prune_symlinks "$TOOLS_SHARE"
  log "uninstall" "done"
}

# _tool_clean [<name>]
_tool_clean() {
  local target="${1:-}"
  source "${DOTFILES_HOME}/lib/opt.sh"

  if [[ -n "$target" ]]; then
    local cache_dir="${TOOLS_CACHE}/${target}"
    if [[ ! -d "$cache_dir" ]]; then
      log "clean" "no cache for $target"
    else
      rm -rf "$cache_dir"
      log "clean" "$target"
    fi
  else
    local cleaned=0
    while IFS= read -r d; do
      rm -rf "$d"
      log "clean" "$(basename "$d")"
      cleaned=1
    done < <(find "$TOOLS_CACHE" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
    [[ "$cleaned" -eq 1 ]] || log "clean" "cache already empty"
  fi
}

# _tool_upgrade [<name>]
# Upgrade installed tools to latest version.
# Skips tools already at the latest version via tool_gh_install's tag check.
# Sets DOTFILES_TOOL_UPGRADE=1 so scripts bypass the command -v early exit.
_tool_upgrade() {
  local target="${1:-}"
  local tools_dir="${DOTFILES_HOME}/tools"

  _tool_ensure_gh || abort "gh is required for tool management and could not be bootstrapped"
  [[ -d "$tools_dir" ]] || abort "tools directory not found: $tools_dir"
  source "${DOTFILES_HOME}/lib/opt.sh"

  export DOTFILES_TOOL_UPGRADE=1

  if [[ -n "$target" ]]; then
    local script="${tools_dir}/${target}.sh"
    [[ -f "$script" ]] || abort "Unknown tool: $target"
    local cmd
    cmd="$(_tool_cmd_name "$script")"
    if [[ ! -f "${TOOLS_STATE}/${target}" ]] && ! command -v "$cmd" >/dev/null 2>&1; then
      abort "$target is not installed (nothing to upgrade)"
    fi
    vlog "tool" "upgrade $target"
    if tool_is_recipe "$script"; then
      tool_run_recipe "$script"
    else
      bash "$script"
    fi
  else
    local failed=0
    export DOTFILES_TOOL_SKIP_EXTERNAL=1
    while IFS= read -r script; do
      local tool_name cmd
      tool_name="$(basename "$script" .sh)"
      cmd="$(_tool_cmd_name "$script")"
      # Skip tools that are neither tracked in state nor available on PATH
      if [[ ! -f "${TOOLS_STATE}/${tool_name}" ]] && ! command -v "$cmd" >/dev/null 2>&1; then
        continue
      fi
      TOOLS_INSTALL_SKIPPED=0
      if tool_is_recipe "$script"; then
        tool_run_recipe "$script" || {
          warn "$tool_name" "upgrade failed"
          failed=1
        }
      else
        bash "$script" || {
          warn "$tool_name" "upgrade failed"
          failed=1
        }
      fi
      if [[ "${TOOLS_INSTALL_SKIPPED:-0}" -eq 1 ]]; then
        continue
      fi
    done < <(find "$tools_dir" -maxdepth 1 -name "*.sh" 2>/dev/null | sort)
    unset DOTFILES_TOOL_SKIP_EXTERNAL
    return $failed
  fi
}

# _tool_outdated
# Show tools that have a newer version available.
# Only checks tools with TOOL_REPO (GitHub release tracking).
# Self-update and externally managed tools are skipped.
_tool_outdated() {
  local tools_dir="${DOTFILES_HOME}/tools"

  _tool_ensure_gh || abort "gh is required for tool management and could not be bootstrapped"
  [[ -d "$tools_dir" ]] || abort "tools directory not found: $tools_dir"
  source "${DOTFILES_HOME}/lib/opt.sh"

  local -a names=() installed=() latest=()
  while IFS= read -r script; do
    local name cmd
    name="$(basename "$script" .sh)"
    cmd="$(_tool_cmd_name "$script")"

    # Reset recipe state
    unset TOOL_CMD TOOL_TYPE TOOL_REPO TOOL_BREW TOOL_LINKS TOOL_MAN_PAGES TOOL_COMPLETIONS
    unset TOOL_STRIP_COMPONENTS TOOL_VERSION_ARGS TOOL_VERSION_MATCH
    unset TOOL_ASSET_MACOS_ARM64 TOOL_ASSET_LINUX_ARM64 TOOL_ASSET_LINUX_AMD64
    unset TOOL_DESKTOP_ID TOOL_DESKTOP_EXEC TOOL_DESKTOP_ICON_EXT TOOL_APPIMAGE_GLOB
    unset TOOL_INSTALL_URL TOOL_INSTALL_ENV TOOL_INSTALL_ARGS
    unset -f tool_download tool_post_install tool_platform_check tool_externally_managed tool_upgrade tool_uninstall 2>/dev/null

    source "$script"

    # Skip tools without TOOL_REPO (self-managed, no tag tracking)
    [[ -n "${TOOL_REPO:-}" ]] || continue

    # Skip externally managed tools (unless verbose)
    if declare -f tool_externally_managed >/dev/null 2>&1 && tool_externally_managed 2>/dev/null; then
      vlog "skip" "${name} externally managed"
      continue
    fi

    # Skip if not installed
    if [[ ! -f "${TOOLS_STATE}/${name}" ]] && ! command -v "$cmd" >/dev/null 2>&1; then
      continue
    fi

    local cur_tag latest_tag
    cur_tag="$(tool_installed_tag "$TOOL_REPO")"
    latest_tag="$(tool_latest_tag "$TOOL_REPO" 2>/dev/null)" || { warn "$name" "failed to check latest version"; continue; }

    [[ -n "$latest_tag" ]] || continue
    [[ "$cur_tag" != "$latest_tag" ]] || continue

    names+=("$name")
    installed+=("$cur_tag")
    latest+=("$latest_tag")
  done < <(find "$tools_dir" -maxdepth 1 -name "*.sh" 2>/dev/null | sort)

  if [[ ${#names[@]} -eq 0 ]]; then
    vlog "outdated" "all tools are up to date"
    return 0
  fi

  # Compute column widths
  local w_name=4 w_installed=9 w_latest=6
  for i in "${!names[@]}"; do
    [[ ${#names[$i]} -gt $w_name ]] && w_name=${#names[$i]}
    [[ ${#installed[$i]} -gt $w_installed ]] && w_installed=${#installed[$i]}
    [[ ${#latest[$i]} -gt $w_latest ]] && w_latest=${#latest[$i]}
  done

  local sep_name sep_installed sep_latest
  sep_name="$(printf '─%.0s' $(seq 1 $w_name))"
  sep_installed="$(printf '─%.0s' $(seq 1 $w_installed))"
  sep_latest="$(printf '─%.0s' $(seq 1 $w_latest))"

  printf "  ${tty_bold}%-${w_name}s  %-${w_installed}s  %s${tty_reset}\n" "TOOL" "INSTALLED" "LATEST"
  printf "  %-${w_name}s  %-${w_installed}s  %s\n" "$sep_name" "$sep_installed" "$sep_latest"
  for i in "${!names[@]}"; do
    printf "  %-${w_name}s  %-${w_installed}s  %s\n" "${names[$i]}" "${installed[$i]}" "${latest[$i]}"
  done

  printf "\n  %d tool%s outdated\n" "${#names[@]}" "$([[ ${#names[@]} -eq 1 ]] && printf '' || printf 's')"
}

# _tool_cmd_name <script>
# Extract the command name from a tool script.
# Checks for declarative TOOL_CMD= first, then tool_check call.
# Falls back to the script basename if neither is found.
_tool_cmd_name() {
  local script="$1"
  local cmd

  # Declarative style: TOOL_CMD=<name>
  cmd="$(grep -m1 '^TOOL_CMD=' "$script" 2>/dev/null | sed 's/^TOOL_CMD=//')"
  if [[ -n "$cmd" ]]; then
    printf '%s' "$cmd"
    return 0
  fi

  # Imperative style: tool_check <name>
  cmd="$(grep -m1 'tool_check ' "$script" 2>/dev/null | awk '{print $2}')"
  if [[ -n "$cmd" ]]; then
    printf '%s' "$cmd"
  else
    printf '%s' "$(basename "$script" .sh)"
  fi
}

# _tool_detect_version <cmd_path> [version_args]
# Run the command with version args and extract a version string.
# Default args: --version. Override with TOOL_VERSION_ARGS in recipes.
_tool_detect_version() {
  local cmd="$1"
  local args="${2:---version}"
  local output=""

  output="$("$cmd" $args 2>&1 || true)"

  # Extract first version-like pattern from output
  local ver
  ver="$(printf '%s' "$output" | grep -oE '(v?[0-9]+\.[0-9]+[.0-9a-zA-Z_-]*)' | head -n1)"
  if [[ -n "$ver" ]]; then
    printf '%s' "$ver"
  else
    printf '-'
  fi
}

# _tool_list
# List installed tools with source type and version.
# Only shows tools managed by us (state file or binary in ~/.local/).
# Respects global VERBOSE flag to show PATH column.
_tool_list() {
  local verbose="${VERBOSE:-0}"

  local tools_dir="${DOTFILES_HOME}/tools"
  [[ -d "$tools_dir" ]] || abort "tools directory not found: $tools_dir"
  source "${DOTFILES_HOME}/lib/opt.sh"

  local -a scripts=()
  while IFS= read -r s; do
    scripts+=("$s")
  done < <(find "$tools_dir" -maxdepth 1 -name "*.sh" 2>/dev/null | sort)

  local -a names=() sources=() versions=() paths=()
  for script in "${scripts[@]}"; do
    local name cmd
    name="$(basename "$script" .sh)"
    cmd="$(_tool_cmd_name "$script")"

    # Source recipe to read all state at once
    unset TOOL_CMD TOOL_TYPE TOOL_REPO TOOL_BREW TOOL_VERSION_ARGS TOOL_VERSION_MATCH TOOL_LINKS TOOL_MAN_PAGES TOOL_COMPLETIONS
    unset TOOL_STRIP_COMPONENTS
    unset TOOL_ASSET_MACOS_ARM64 TOOL_ASSET_LINUX_ARM64 TOOL_ASSET_LINUX_AMD64
    unset TOOL_DESKTOP_ID TOOL_DESKTOP_EXEC TOOL_DESKTOP_ICON_EXT TOOL_APPIMAGE_GLOB
    unset TOOL_INSTALL_URL TOOL_INSTALL_ENV TOOL_INSTALL_ARGS
    unset -f tool_download tool_post_install tool_platform_check tool_externally_managed tool_uninstall tool_upgrade tool_version 2>/dev/null
    source "$script"

    # Resolve command path — prefer our managed binary over system
    local cmd_path=""
    if [[ -x "${XDG_OPT_BIN}/${cmd}" ]]; then
      cmd_path="${XDG_OPT_BIN}/${cmd}"
    elif command -v "$cmd" >/dev/null 2>&1; then
      cmd_path="$(command -v "$cmd")"
    fi

    # Classify: externally managed with no managed binary → skipped (verbose only)
    local is_managed=0
    if [[ -n "$cmd_path" ]]; then
      case "$cmd_path" in
        "$HOME/.local/"*) is_managed=1 ;;
      esac
    fi

    # Check externally managed (hook or TOOL_TYPE=appimage on macOS)
    local is_external=0
    if declare -f tool_externally_managed >/dev/null 2>&1 && tool_externally_managed 2>/dev/null; then
      is_external=1
    elif [[ "${TOOL_TYPE:-}" == "appimage" && "$(uname -s)" == "Darwin" ]]; then
      is_external=1
    fi

    if [[ "$is_external" -eq 1 && "$is_managed" -eq 0 ]]; then
      if [[ "$verbose" -eq 1 ]]; then
        names+=("$name")
        sources+=("skipped")
        versions+=("-")
        paths+=("-")
      fi
      continue
    fi

    names+=("$name")

    # Determine source type — prefer explicit TOOL_TYPE, fall back to inference
    if [[ -n "${TOOL_TYPE:-}" ]]; then
      sources+=("$TOOL_TYPE")
    elif [[ -n "${TOOL_REPO:-}" ]]; then
      sources+=("github")
    elif declare -f tool_download >/dev/null 2>&1; then
      sources+=("self-install")
    else
      sources+=("unknown")
    fi

    # Detect version for installed tools
    if [[ "$is_managed" -eq 1 ]]; then
      if declare -f tool_version >/dev/null 2>&1; then
        versions+=("$(tool_version "$cmd_path" 2>/dev/null || echo '-')")
      elif [[ "${TOOL_TYPE:-}" == "appimage" && -n "${TOOL_REPO:-}" ]]; then
        # AppImage: use persisted tag metadata instead of running the binary
        local repo_name="${TOOL_REPO##*/}"
        if [[ -f "${TOOLS_STATE}/${repo_name}" ]]; then
          local tag
          tag="$(cat "${TOOLS_STATE}/${repo_name}")"
          if [[ -n "${TOOL_VERSION_MATCH:-}" && "$tag" =~ ${TOOL_VERSION_MATCH} ]]; then
            versions+=("${BASH_REMATCH[1]}")
          else
            versions+=("$tag")
          fi
        else
          versions+=("-")
        fi
      else
        versions+=("$(_tool_detect_version "$cmd_path" "${TOOL_VERSION_ARGS:-}")")
      fi
      paths+=("$cmd_path")
    else
      versions+=("")
      paths+=("-")
    fi
  done

  if [[ ${#names[@]} -eq 0 ]]; then
    printf "  no tools installed\n"
    return 0
  fi

  # Compute column widths
  local w_name=4 w_source=6 w_version=7 w_path=4
  for i in "${!names[@]}"; do
    [[ ${#names[$i]} -gt $w_name ]] && w_name=${#names[$i]}
    [[ ${#sources[$i]} -gt $w_source ]] && w_source=${#sources[$i]}
    [[ ${#versions[$i]} -gt $w_version ]] && w_version=${#versions[$i]}
    [[ ${#paths[$i]} -gt $w_path ]] && w_path=${#paths[$i]}
  done

  local sep_name sep_source sep_version sep_path
  sep_name="$(printf '─%.0s' $(seq 1 $w_name))"
  sep_source="$(printf '─%.0s' $(seq 1 $w_source))"
  sep_version="$(printf '─%.0s' $(seq 1 $w_version))"
  sep_path="$(printf '─%.0s' $(seq 1 $w_path))"

  if [[ "$verbose" -eq 1 ]]; then
    printf "  ${tty_bold}%-${w_name}s  %-${w_source}s  %-${w_version}s  %s${tty_reset}\n" "TOOL" "SOURCE" "VERSION" "PATH"
    printf "  %-${w_name}s  %-${w_source}s  %-${w_version}s  %s\n" "$sep_name" "$sep_source" "$sep_version" "$sep_path"
    for i in "${!names[@]}"; do
      printf "  %-${w_name}s  %-${w_source}s  %-${w_version}s  %s\n" \
        "${names[$i]}" "${sources[$i]}" "${versions[$i]}" "${paths[$i]}"
    done
  else
    printf "  ${tty_bold}%-${w_name}s  %-${w_source}s  %s${tty_reset}\n" "TOOL" "SOURCE" "VERSION"
    printf "  %-${w_name}s  %-${w_source}s  %s\n" "$sep_name" "$sep_source" "$sep_version"
    for i in "${!names[@]}"; do
      printf "  %-${w_name}s  %-${w_source}s  %s\n" "${names[$i]}" "${sources[$i]}" "${versions[$i]}"
    done
  fi

  # Count installed (non-empty version, non-skipped)
  local installed=0
  for i in "${!versions[@]}"; do
    [[ -n "${versions[$i]}" && "${sources[$i]}" != "skipped" ]] && installed=$((installed + 1))
  done

  printf "\n  %d tool%s installed\n" "$installed" "$([[ $installed -eq 1 ]] && printf '' || printf 's')"
}

# _tool_cmd <op> [<name>]
# Main dispatcher — called by cmd_tool in bin/dotfiles.
_tool_cmd() {
  local op="${1:-}"
  shift 2>/dev/null || true

  [[ -n "${DOTFILES_HOME:-}" ]] || abort "DOTFILES_HOME is not set"

  case "$op" in
    install)   _tool_install   "$@" ;;
    uninstall) _tool_uninstall "$@" ;;
    upgrade)   _tool_upgrade   "$@" ;;
    outdated)  _tool_outdated ;;
    clean)     _tool_clean     "$@" ;;
    list)      _tool_list ;;
    status)    _tool_status ;;
    "")
      abort "usage: dotfiles tool <install|uninstall|upgrade|outdated|clean|list|status> [<toolname>]"
      ;;
    *)
      abort "unknown tool operation: $op (use install, uninstall, upgrade, outdated, clean, list, or status)"
      ;;
  esac
}
