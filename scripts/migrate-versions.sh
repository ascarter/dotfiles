#!/usr/bin/env bash
set -eu

# migrate-versions.sh — one-time migration to normalized version layout
#
# Migrates:
#   1. State/cache dirs from ~/.local/state/tools/ to ~/.local/state/dotfiles/tools/
#      and ~/.cache/tools/ to ~/.cache/dotfiles/tools/
#   2. Cellar dirs from raw tags (v0.70.0) to normalized versions (0.70.0)
#   3. Symlinks in opt/bin and opt/share to match renamed cellar paths
#   4. State files from raw tags to normalized versions
#
# Safe to run multiple times — skips already-migrated items.
# Usage: dotfiles script migrate-versions

: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/.." && pwd)}"
source "${DOTFILES_HOME}/lib/core.sh"
source "${DOTFILES_HOME}/lib/opt.sh"

# --- Phase 1: Directory namespace ---

old_state="${XDG_STATE_HOME}/tools"
old_cache="${XDG_CACHE_HOME}/tools"

if [[ -d "$old_state" && ! -d "$TOOLS_STATE" ]]; then
  mkdir -p "$(dirname "$TOOLS_STATE")"
  mv "$old_state" "$TOOLS_STATE"
  log "migrate" "state: ${old_state} -> ${TOOLS_STATE}"
elif [[ -d "$old_state" ]]; then
  warn "migrate" "both ${old_state} and ${TOOLS_STATE} exist — resolve manually"
fi

if [[ -d "$old_cache" && ! -d "$TOOLS_CACHE" ]]; then
  mkdir -p "$(dirname "$TOOLS_CACHE")"
  mv "$old_cache" "$TOOLS_CACHE"
  log "migrate" "cache: ${old_cache} -> ${TOOLS_CACHE}"
elif [[ -d "$old_cache" ]]; then
  warn "migrate" "both ${old_cache} and ${TOOLS_CACHE} exist — resolve manually"
fi

# --- Phase 2: Cellar version normalization ---

migrated=0

_migrate_recipes() {
  local recipe_dir="$1"
  [[ -d "$recipe_dir" ]] || return 0

  for recipe in "$recipe_dir"/*.sh; do
    [[ -f "$recipe" ]] || continue
    local name
    name="$(basename "$recipe" .sh)"
    local state_file="${TOOLS_STATE}/${name}"

    [[ -f "$state_file" ]] || continue

    # Reset and source recipe to get TOOL_VERSION_MATCH
    unset TOOL_VERSION_MATCH 2>/dev/null || true
    TOOL_CMD="" TOOL_TYPE="" TOOL_REPO="" FONT_REPO="" FONT_ASSET=""
    source "$recipe" 2>/dev/null || continue

    local raw_tag normalized
    raw_tag="$(cat "$state_file")"
    normalized="$(_tool_normalize_version "$raw_tag" 2>/dev/null)" || continue

    [[ "$raw_tag" != "$normalized" ]] || continue

    local old_dir="${TOOLS_CELLAR}/${name}/${raw_tag}"
    local new_dir="${TOOLS_CELLAR}/${name}/${normalized}"

    # Update state file
    printf '%s\n' "$normalized" > "$state_file"

    # Rename cellar dir
    if [[ -d "$old_dir" && ! -d "$new_dir" ]]; then
      mv "$old_dir" "$new_dir"

      # Fix symlinks pointing to old path
      while IFS= read -r link; do
        [[ -L "$link" ]] || continue
        local target
        target="$(readlink "$link")"
        if [[ "$target" == *"${old_dir}"* ]]; then
          ln -sf "${target/${old_dir}/${new_dir}}" "$link"
        fi
      done < <(find "${XDG_OPT_BIN}" "${XDG_OPT_SHARE}" -type l 2>/dev/null)
    fi

    log "migrate" "${name}: ${raw_tag} -> ${normalized}"
    migrated=$((migrated + 1))
  done
}

_migrate_recipes "${DOTFILES_HOME}/tools"
_migrate_recipes "${DOTFILES_HOME}/fonts"

if [[ "$migrated" -eq 0 ]]; then
  success "nothing to migrate — already up to date"
else
  success "migrated ${migrated} item(s)"
fi
