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

# _tool_install [<name>]
_tool_install() {
  local target="${1:-}"
  local tools_dir="${DOTFILES_HOME}/tools"

  command -v gh >/dev/null 2>&1 \
    || abort "gh is required for tool management. Install via: dotfiles script tools/gh"
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
    while IFS= read -r script; do
      local tool_name
      tool_name="$(basename "$script" .sh)"
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
  unset TOOL_CMD TOOL_REPO TOOL_LINKS TOOL_MAN_PAGES TOOL_COMPLETIONS
  unset TOOL_STRIP_COMPONENTS
  unset TOOL_ASSET_MACOS_ARM64
  unset TOOL_ASSET_LINUX_ARM64 TOOL_ASSET_LINUX_AMD64
  unset -f tool_download tool_post_install tool_platform_check tool_uninstall 2>/dev/null

  source "$script"

  if declare -f tool_uninstall >/dev/null 2>&1; then
    log "uninstall" "running hook for $name"
    if [[ "$force" -eq 1 ]]; then
      tool_uninstall || warn "$name" "uninstall hook failed (continuing with --force)"
    else
      tool_uninstall || { error "uninstall hook failed for $name"; return 1; }
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
      abort "$target is not installed in cellar (use --force to clean up broken installs)"
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

  command -v gh >/dev/null 2>&1 \
    || abort "gh is required for tool management. Install via: dotfiles script tools/gh"
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
    local failed=0 upgraded=0 up_to_date=0
    while IFS= read -r script; do
      local tool_name cmd
      tool_name="$(basename "$script" .sh)"
      cmd="$(_tool_cmd_name "$script")"
      # Skip tools that are neither tracked in state nor available on PATH
      if [[ ! -f "${TOOLS_STATE}/${tool_name}" ]] && ! command -v "$cmd" >/dev/null 2>&1; then
        continue
      fi
      vlog "tool" "upgrade $tool_name"
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
        up_to_date=$((up_to_date + 1))
      else
        upgraded=$((upgraded + 1))
      fi
    done < <(find "$tools_dir" -maxdepth 1 -name "*.sh" 2>/dev/null | sort)
    if [[ "$upgraded" -gt 0 ]]; then
      log "upgrade" "$upgraded upgraded"
    fi
    return $failed
  fi
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

# _tool_list
# List available tool scripts and their install status.
_tool_list() {
  local tools_dir="${DOTFILES_HOME}/tools"
  [[ -d "$tools_dir" ]] || abort "tools directory not found: $tools_dir"
  source "${DOTFILES_HOME}/lib/opt.sh"

  local -a names=() statuses=()
  while IFS= read -r script; do
    local name cmd
    name="$(basename "$script" .sh)"
    cmd="$(_tool_cmd_name "$script")"
    names+=("$name")
    if [[ -f "${TOOLS_STATE}/${name}" ]]; then
      statuses+=("$(cat "${TOOLS_STATE}/${name}")")
    elif command -v "$cmd" >/dev/null 2>&1; then
      statuses+=("$(command -v "$cmd")")
    else
      statuses+=("—")
    fi
  done < <(find "$tools_dir" -maxdepth 1 -name "*.sh" 2>/dev/null | sort)

  if [[ ${#names[@]} -eq 0 ]]; then
    printf "  no tool scripts found\n"
    return 0
  fi

  # Compute column widths
  local w_name=4 w_status=6
  for i in "${!names[@]}"; do
    [[ ${#names[$i]} -gt $w_name ]] && w_name=${#names[$i]}
    [[ ${#statuses[$i]} -gt $w_status ]] && w_status=${#statuses[$i]}
  done

  local sep_name sep_status
  sep_name="$(printf '─%.0s' $(seq 1 $w_name))"
  sep_status="$(printf '─%.0s' $(seq 1 $w_status))"

  printf "  ${tty_bold}%-${w_name}s  %s${tty_reset}\n" "TOOL" "STATUS"
  printf "  %-${w_name}s  %s\n" "$sep_name" "$sep_status"
  for i in "${!names[@]}"; do
    printf "  %-${w_name}s  %s\n" "${names[$i]}" "${statuses[$i]}"
  done

  printf "\n  %d tool%s available\n" "${#names[@]}" "$([[ ${#names[@]} -eq 1 ]] && printf '' || printf 's')"
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
    clean)     _tool_clean     "$@" ;;
    list)      _tool_list ;;
    status)    _tool_status ;;
    "")
      abort "usage: dotfiles tool <install|uninstall|upgrade|clean|list|status> [<toolname>]"
      ;;
    *)
      abort "unknown tool operation: $op (use install, uninstall, upgrade, clean, list, or status)"
      ;;
  esac
}
