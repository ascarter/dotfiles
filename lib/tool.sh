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

# _print_tool_table [<name>]
# Print a table of installed tools and their tags.
# If <name> is given, show only that tool.
_print_tool_table() {
  local filter="${1:-}"
  source "${DOTFILES_HOME}/lib/opt.sh"

  local -a names tags
  while IFS= read -r f; do
    local name tag
    name="$(basename "$f")"
    tag="$(cat "$f")"
    [[ -n "$filter" && "$name" != "$filter" ]] && continue
    names+=("$name")
    tags+=("$tag")
  done < <(find "$TOOLS_STATE" -maxdepth 1 -type f 2>/dev/null | sort)

  if [[ ${#names[@]} -eq 0 ]]; then
    [[ -n "$filter" ]] \
      && printf "  %s is not installed\n" "$filter" \
      || printf "  no tools installed\n"
    return 0
  fi

  # Compute column widths (minimum = header label length)
  local w_name=4 w_tag=3
  for i in "${!names[@]}"; do
    [[ ${#names[$i]} -gt $w_name ]] && w_name=${#names[$i]}
    [[ ${#tags[$i]}  -gt $w_tag  ]] && w_tag=${#tags[$i]}
  done

  local sep_name sep_tag
  sep_name="$(printf '─%.0s' $(seq 1 $w_name))"
  sep_tag="$(printf '─%.0s' $(seq 1 $w_tag))"

  printf "  ${tty_bold}%-${w_name}s  %s${tty_reset}\n" "TOOL" "TAG"
  printf "  %-${w_name}s  %s\n" "$sep_name" "$sep_tag"
  for i in "${!names[@]}"; do
    printf "  %-${w_name}s  %s\n" "${names[$i]}" "${tags[$i]}"
  done

  # Count footer only when showing all tools
  if [[ -z "$filter" ]]; then
    local count=${#names[@]}
    printf "\n  %d tool%s installed\n" "$count" "$([[ $count -eq 1 ]] && printf '' || printf 's')"
  fi
}

# _tool_install [<name>]
_tool_install() {
  local target="${1:-}"
  local tools_dir="${DOTFILES_HOME}/tools"

  command -v gh >/dev/null 2>&1 \
    || abort "gh is required for tool management. Install via: dotfiles script tools/gh"
  [[ -d "$tools_dir" ]] || abort "tools directory not found: $tools_dir"

  if [[ -n "$target" ]]; then
    local script="${tools_dir}/${target}.sh"
    [[ -f "$script" ]] || abort "Unknown tool: $target"
    vlog "tool" "install $target"
    bash "$script"
  else
    local failed=0
    while IFS= read -r script; do
      local tool_name
      tool_name="$(basename "$script" .sh)"
      vlog "tool" "install $tool_name"
      bash "$script" || {
        warn "$tool_name" "installation failed"
        failed=1
      }
    done < <(find "$tools_dir" -maxdepth 1 -name "*.sh" | sort)
    return $failed
  fi
}

# _tool_uninstall [<name>]
_tool_uninstall() {
  local target="${1:-}"
  source "${DOTFILES_HOME}/lib/opt.sh"

  if [[ -n "$target" ]]; then
    local install_dir="${TOOLS_CELLAR}/${target}"
    if [[ ! -d "$install_dir" ]]; then
      abort "$target is not installed in cellar (only tools installed via tool_gh_install can be uninstalled this way)"
    fi
    rm -rf "$install_dir"
    log "uninstall" "$target"
    rm -f "${TOOLS_STATE}/${target}"
  else
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

# _tool_cmd <op> [<name>]
# Main dispatcher — called by cmd_tool in bin/dotfiles.
_tool_cmd() {
  local op="${1:-}"
  local target="${2:-}"

  [[ -n "${DOTFILES_HOME:-}" ]] || abort "DOTFILES_HOME is not set"

  case "$op" in
    install)   _tool_install   "$target" ;;
    uninstall) _tool_uninstall "$target" ;;
    clean)     _tool_clean     "$target" ;;
    status)    _print_tool_table "$target" ;;
    "")
      abort "usage: dotfiles tool <install|uninstall|clean|status> [<toolname>]"
      ;;
    *)
      abort "unknown tool operation: $op (use install, uninstall, clean, or status)"
      ;;
  esac
}
