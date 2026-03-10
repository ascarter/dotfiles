# lib/sync.sh — config symlink synchronization
#
# Sourced on demand by cmd_sync, cmd_status, cmd_uninstall, cmd_update in bin/dotfiles.
# Requires lib/core.sh to be sourced first (for log/vlog/warn/prompt globals).
# No shebang — this file is sourced, not executed.
#
# Provides: _sync <action>
#   action: link | unlink | status

# Idempotent guard
[[ -n "${_DOTFILES_SYNC_LOADED:-}" ]] && return 0
_DOTFILES_SYNC_LOADED=1

_sync() {
  # Action to apply for each file
  # Actions: link | unlink | status
  action=${1:-status}

  # Synchronize config/ into XDG config home
  XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
  SRC="${DOTFILES_HOME}/config/"
  DEST="${XDG_CONFIG_HOME}/"

  # Files and patterns to exclude from linking
  EXCLUDE_PATTERNS=".DS_Store Thumbs.db *.tmp .gitkeep"

  find_cmd="find \"$SRC\" -type f"
  for pattern in $EXCLUDE_PATTERNS; do
    find_cmd="$find_cmd -not -name \"$pattern\""
  done

  vlog "$action" "$SRC -> $DEST"

  log_sync() {
    label="$1"
    shift
    case "$label" in
    link | unlink | ok)
      [ "$QUIET" -ne 1 ] && log "$label" "$@"
      return 0
      ;;
    *)
      [ "$QUIET" -ne 1 ] && warn "$label" "$@"
      return 1
      ;;
    esac
  }

  link() {
    src_path="$1"
    dest_path="$2"
    rel_src="${src_path#$SRC}"

    if [ -e "$dest_path" ] && [ "$FORCE" -eq 1 ]; then
      unlink "$src_path" "$dest_path"
    fi

    if [ -e "$dest_path" ]; then
      status "$src_path" "$dest_path"
    else
      mkdir -p "$(dirname "$dest_path")"
      ln -s "$src_path" "$dest_path"
      log_sync "link" "$rel_src" "$dest_path -> $src_path"
    fi
  }

  unlink() {
    src_path="$1"
    dest_path="$2"
    rel_src="${src_path#$SRC}"

    compare_files() {
      if cmp -s "$dest_path" "$src_path"; then
        printf "matches source"
      else
        printf "differs from source"
      fi
    }

    if [ -L "$dest_path" ]; then
      existing_target=$(readlink "$dest_path")
      if [ "$existing_target" = "$src_path" ]; then
        rm "$dest_path"
        log_sync "unlink" "$rel_src" "removed $dest_path"
      elif [ "$FORCE" -eq 1 ] && prompt "Symlink $dest_path points to $existing_target instead of $rel_src. Remove?"; then
        rm "$dest_path"
        log_sync "unlink" "$rel_src" "deleted $dest_path -> $existing_target)"
      else
        log_sync "skip" "$rel_src" "ignore $dest_path -> $existing_target"
      fi
    else
      if [ -e "$dest_path" ]; then
        if [ "$FORCE" -eq 1 ] && prompt "$dest_path exists and $(compare_files "$src_path" "$dest_path"). Remove?"; then
          rm -rf "$dest_path"
          log_sync "deleted" "$rel_src" "deleted $dest_path"
        else
          log_sync "skip" "$dest_path"
        fi
      else
        log_sync "missing" "$dest_path"
      fi
    fi
  }

  status() {
    src_path="$1"
    dest_path="$2"
    rel_src="${src_path#$SRC}"

    if [ -L "$dest_path" ]; then
      existing_target=$(readlink "$dest_path")
      if [ "$existing_target" = "$src_path" ]; then
        if [ "$VERBOSE" -eq 1 ]; then
          log_sync "ok" "$rel_src"
        fi
      else
        log_sync "conflict" "$rel_src" "$dest_path -> $existing_target"
      fi
    else
      if [ -e "$dest_path" ]; then
        if cmp -s "$dest_path" "$src_path"; then
          log_sync "exists" "$rel_src" "$dest_path matches source"
        else
          log_sync "conflict" "$rel_src" "$dest_path differs from source"
        fi
      else
        log_sync "missing" "$rel_src" "no file at $dest_path"
      fi
    fi
  }

  eval "$find_cmd" | sort | (
    RC=0
    while read -r source_file; do
      target_file="${DEST}${source_file#$SRC}"
      if ! $action "$source_file" "$target_file"; then
        RC=1
      fi
    done
    return $RC
  )
}
