# lib/flatpak.sh — declarative Flatpak app management
#
# Sourced on demand by cmd_flatpak in bin/dotfiles.
# Requires lib/core.sh to be sourced first (for log/warn/error globals).
# No shebang — this file is sourced, not executed.
#
# Provides: _flatpak_cmd <action>
#   action: install | status

# Idempotent guard
[[ -n "${_DOTFILES_FLATPAK_LOADED:-}" ]] && return 0
_DOTFILES_FLATPAK_LOADED=1

FLATPAK_LIST="${DOTFILES_HOME}/host/flatpak"

_flatpak_read_list() {
  [[ -f "$FLATPAK_LIST" ]] || { error "Flatpak list not found: $FLATPAK_LIST"; return 1; }
  sed 's/#.*//; /^[[:space:]]*$/d' "$FLATPAK_LIST"
}

_flatpak_ensure_flathub() {
  if ! flatpak remote-list --user --columns=name 2>/dev/null | grep -qx "flathub"; then
    log "flatpak" "Adding Flathub remote"
    flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  fi
}

_flatpak_install() {
  _flatpak_ensure_flathub

  log "flatpak" "Updating installed Flatpaks"
  flatpak update --user -y --noninteractive

  local app_id
  local rc=0
  while IFS= read -r app_id; do
    if flatpak info --user "$app_id" >/dev/null 2>&1; then
      vlog "flatpak" "already installed: $app_id"
    else
      log "flatpak" "Installing $app_id"
      if ! flatpak install --user -y --noninteractive flathub "$app_id"; then
        warn "flatpak" "Failed to install $app_id"
        rc=1
      fi
    fi
  done < <(_flatpak_read_list)

  if [[ "$rc" -eq 0 ]]; then
    log "flatpak" "ok"
  fi
  return $rc
}

_flatpak_status() {
  local -a wanted=()
  local -a installed=()

  while IFS= read -r app_id; do
    wanted+=("$app_id")
  done < <(_flatpak_read_list)

  while IFS= read -r app_id; do
    installed+=("$app_id")
  done < <(flatpak list --user --app --columns=application 2>/dev/null)

  local missing=0 extra=0

  # Missing: in list but not installed
  for app_id in "${wanted[@]}"; do
    local found=0
    for inst in "${installed[@]}"; do
      [[ "$inst" == "$app_id" ]] && { found=1; break; }
    done
    if [[ "$found" -eq 0 ]]; then
      log "missing" "$app_id"
      missing=$((missing + 1))
    else
      vlog "ok" "$app_id"
    fi
  done

  # Extra: installed but not in list
  for inst in "${installed[@]}"; do
    local found=0
    for app_id in "${wanted[@]}"; do
      [[ "$app_id" == "$inst" ]] && { found=1; break; }
    done
    if [[ "$found" -eq 0 ]]; then
      log "extra" "$inst"
      extra=$((extra + 1))
    fi
  done

  if [[ "$missing" -eq 0 && "$extra" -eq 0 ]]; then
    log "flatpak" "ok (${#wanted[@]} apps)"
  fi
}

_flatpak_cmd() {
  local subcommand="${1:-}"
  shift || true

  case "$subcommand" in
  install)
    _flatpak_install
    ;;
  status)
    _flatpak_status
    ;;
  "")
    cat <<'EOF'
Usage:
  dotfiles flatpak install   Install Flatpak apps from host/flatpak list
  dotfiles flatpak status    Show missing or extra apps vs the list
EOF
    exit 1
    ;;
  *)
    error "Unknown flatpak subcommand: $subcommand"
    cat <<'EOF'
Usage:
  dotfiles flatpak install   Install Flatpak apps from host/flatpak list
  dotfiles flatpak status    Show missing or extra apps vs the list
EOF
    exit 1
    ;;
  esac
}
