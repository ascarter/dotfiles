# lib/cache.sh — cache subcommand implementation for bin/dotfiles
#
# Sourced on demand by cmd_cache in bin/dotfiles.
# Inherits log/warn/abort/vlog/error and tty_* variables from the caller.
#
# No shebang — this file is sourced, not executed.

# Idempotent guard
[[ -n "${_DOTFILES_CACHE_LOADED:-}" ]] && return 0
_DOTFILES_CACHE_LOADED=1

# _cache_status
# Show cache location and disk usage.
_cache_status() {
  source "${DOTFILES_HOME}/lib/opt.sh"

  printf "  ${tty_bold}Cache${tty_reset}\n"
  printf "  %-8s %s\n" "path:" "$TOOLS_CACHE"

  if [[ ! -d "$TOOLS_CACHE" ]]; then
    printf "  %-8s %s\n" "size:" "0B (not created)"
    return 0
  fi

  local total_size
  total_size="$(du -sh "$TOOLS_CACHE" 2>/dev/null | cut -f1 | tr -d ' ')"
  printf "  %-8s %s\n" "size:" "$total_size"

  local count=0
  local -a names=() sizes=()
  while IFS= read -r d; do
    local name size
    name="$(basename "$d")"
    size="$(du -sh "$d" 2>/dev/null | cut -f1 | tr -d ' ')"
    names+=("$name")
    sizes+=("$size")
    count=$((count + 1))
  done < <(find "$TOOLS_CACHE" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)

  if [[ "$count" -gt 0 ]]; then
    printf "\n  ${tty_bold}%-20s  %s${tty_reset}\n" "NAME" "SIZE"
    local sep
    sep="$(printf '─%.0s' $(seq 1 20))"
    printf "  %-20s  %s\n" "$sep" "────"
    for i in "${!names[@]}"; do
      printf "  %-20s  %s\n" "${names[$i]}" "${sizes[$i]}"
    done
    printf "\n  %d item%s cached\n" "$count" "$([[ $count -eq 1 ]] && printf '' || printf 's')"
  else
    printf "  cache is empty\n"
  fi
}

# _cache_clean
# Remove all cached download archives.
_cache_clean() {
  source "${DOTFILES_HOME}/lib/opt.sh"

  if [[ ! -d "$TOOLS_CACHE" ]]; then
    log "clean" "cache directory does not exist"
    return 0
  fi

  local cleaned=0
  while IFS= read -r d; do
    rm -rf "$d"
    log "clean" "$(basename "$d")"
    cleaned=1
  done < <(find "$TOOLS_CACHE" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)

  [[ "$cleaned" -eq 1 ]] || log "clean" "cache already empty"
}

# _cache_cmd <op>
# Main dispatcher — called by cmd_cache in bin/dotfiles.
_cache_cmd() {
  local op="${1:-}"
  shift 2>/dev/null || true

  [[ -n "${DOTFILES_HOME:-}" ]] || abort "DOTFILES_HOME is not set"

  case "$op" in
    status) _cache_status ;;
    clean)  _cache_clean ;;
    "")
      abort "usage: dotfiles cache <status|clean>"
      ;;
    *)
      abort "unknown cache operation: $op (use status or clean)"
      ;;
  esac
}
