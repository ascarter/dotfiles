#!/usr/bin/env bash
#
# Update Neovim plugins, treesitter parsers, and Mason tools headlessly.
# Cleans up legacy lazy.nvim artifacts if present.
#
# Usage: dotfiles script nvim-update
#

set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/.." && pwd)}"
source "${DOTFILES_HOME}/lib/logging.sh"

if ! command -v nvim >/dev/null 2>&1; then
  abort "nvim not found"
fi

# ── Clean up legacy lazy.nvim artifacts ────────────────────────────────────────
cleaned=0

if [ -d "${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy" ]; then
  log "nvim" "removing lazy.nvim plugin data"
  rm -rf "${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy"
  cleaned=1
fi

if [ -d "${XDG_STATE_HOME:-$HOME/.local/state}/nvim/lazy" ]; then
  log "nvim" "removing lazy.nvim state"
  rm -rf "${XDG_STATE_HOME:-$HOME/.local/state}/nvim/lazy"
  cleaned=1
fi

if [ -f "${XDG_CONFIG_HOME:-$HOME/.config}/nvim/lazy-lock.json" ]; then
  log "nvim" "removing lazy-lock.json"
  rm -f "${XDG_CONFIG_HOME:-$HOME/.config}/nvim/lazy-lock.json"
  cleaned=1
fi

# ── Clean up legacy nvim-treesitter / echasnovski mini.* artifacts ─────────────
# Migrated to romus204/tree-sitter-manager.nvim and the nvim-mini/* org.
nvim_data="${XDG_DATA_HOME:-$HOME/.local/share}/nvim"
pack_opt="$nvim_data/site/pack/core/opt"
ts_marker="$nvim_data/site/.tree-sitter-manager-migrated"
ts_cleaned=0

for legacy in nvim-treesitter nvim-treesitter-textobjects mini.pairs mini.surround; do
  legacy_dir="$pack_opt/$legacy"
  if [ -d "$legacy_dir" ]; then
    # mini.* is only "legacy" when it points at the old echasnovski remote.
    case "$legacy" in
      mini.*)
        if [ -d "$legacy_dir/.git" ] && \
           git -C "$legacy_dir" remote get-url origin 2>/dev/null | grep -q "echasnovski/"; then
          log "nvim" "removing legacy plugin: $legacy (echasnovski → nvim-mini)"
          rm -rf "$legacy_dir"
          cleaned=1
        fi
        ;;
      *)
        log "nvim" "removing legacy plugin: $legacy"
        rm -rf "$legacy_dir"
        cleaned=1
        ts_cleaned=1
        ;;
    esac
  fi
done

# Reset parser/queries dirs if nvim-treesitter was just removed OR if the
# one-shot migration marker is missing (vim.pack may have removed the legacy
# plugin in a prior run, leaving orphan parsers/queries that conflict with
# tree-sitter-manager.nvim).
if [ "$ts_cleaned" -eq 1 ] || [ ! -f "$ts_marker" ]; then
  for d in parser queries; do
    if [ -d "$nvim_data/site/$d" ]; then
      log "nvim" "resetting tree-sitter $d directory (one-shot migration)"
      rm -rf "$nvim_data/site/$d"
      cleaned=1
    fi
  done
  mkdir -p "$nvim_data/site"
  touch "$ts_marker"
fi

# Remove broken symlinks left by deleted config files
stale=$(find "${XDG_CONFIG_HOME:-$HOME/.config}/nvim" -type l ! -exec test -e {} \; -print 2>/dev/null || true)
if [ -n "$stale" ]; then
  log "nvim" "removing stale symlinks"
  echo "$stale" | while read -r link; do rm -f "$link"; done
  cleaned=1
fi

if [ "$cleaned" -eq 1 ]; then
  log "nvim" "cleanup complete"
  log
fi

# ── Update ─────────────────────────────────────────────────────────────────────
log "nvim" "updating plugins..."
nvim --headless +'lua vim.pack.update(nil, {force=true})' +qa
log

# Update tree-sitter parsers (remove + reinstall each, sequentially).
# Mirrors what `:TSManager` -> 'u' does, driven from a headless nvim session.
log "nvim" "updating tree-sitter parsers..."
ts_update_lua=$(mktemp -t nvim-ts-update.XXXXXX.lua)
trap 'rm -f "$ts_update_lua"' EXIT
cat > "$ts_update_lua" <<'EOF'
local installer = require("tree-sitter-manager.installer")
local cfg       = require("tree-sitter-manager.config").cfg
local parsers   = {}
for name, _ in vim.fs.dir(cfg.parser_dir) do
  local lang = name:match("^(.*)%.so$") or name:match("^(.*)%.dylib$") or name:match("^(.*)%.dll$")
  if lang then table.insert(parsers, lang) end
end
table.sort(parsers)
print("updating " .. #parsers .. " parsers")
for _, lang in ipairs(parsers) do
  local done = false
  installer.remove(lang)
  installer.install(lang, function() done = true end)
  vim.wait(120000, function() return done end, 50)
  if not done then print("⚠ timeout: " .. lang) end
end
print("tree-sitter parser update complete")
EOF
nvim --headless "+luafile $ts_update_lua" +qa
log

success "nvim" "update complete"
