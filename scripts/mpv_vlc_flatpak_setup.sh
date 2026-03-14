#!/bin/sh
# mpv_vlc_flatpak_setup.sh
# Configure mpv and VLC via Flatpak on immutable Fedora systems (also works elsewhere).
# POSIX sh; no Bashisms.

set -eu

APP_MPV="io.mpv.Mpv"
APP_VLC="org.videolan.VLC"

MEDIA_PATH="${HOME}/Videos"
WRITE_ACCESS=0
STRICT=0
CAPTURE=0
WRAPPER_ONLY=0
NO_MIME=0
RESET=0
UNINSTALL=0

usage() {
  cat <<'EOF'
Usage: mpv_vlc_flatpak_setup.sh [options]

Options:
  --media PATH     Media path to expose inside Flatpaks (default: ~/Videos)
  --rw             Grant write access to --media path (default: read-only)
  --strict         Apply a stricter sandbox for mpv (no home, media-only, dri device)
  --capture        Allow access to video/capture devices (--device=all)
  --wrapper-only   Only (re)create CLI wrappers (~/.local/bin/mpv, ~/.local/bin/vlc)
  --no-mime        Skip setting default application associations (xdg-mime)
  --reset          Reset Flatpak overrides for both apps (leaves installs intact)
  --uninstall      Uninstall both Flatpaks (does not touch wrappers)
  -h, --help       Show this help

Examples:
  # Typical setup (RO access to ~/Videos)
  ./mpv_vlc_flatpak_setup.sh

  # Grant RW access to an external drive and allow capture devices
  ./mpv_vlc_flatpak_setup.sh --media /mnt/media --rw --capture

  # Lock down mpv with a strict sandbox, skip MIME defaults
  ./mpv_vlc_flatpak_setup.sh --strict --no-mime
EOF
}

say() { printf '%s\n' "$*"; }
err() { printf '%s\n' "$*" >&2; }
die() { err "ERROR: $*"; exit 1; }

need() {
  command -v "$1" >/dev/null 2>&1 || die "Missing dependency: $1"
}

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --media) [ $# -ge 2 ] || die "--media requires a PATH"; MEDIA_PATH="$2"; shift 2 ;;
      --rw) WRITE_ACCESS=1; shift ;;
      --strict) STRICT=1; shift ;;
      --capture) CAPTURE=1; shift ;;
      --wrapper-only) WRAPPER_ONLY=1; shift ;;
      --no-mime) NO_MIME=1; shift ;;
      --reset) RESET=1; shift ;;
      --uninstall) UNINSTALL=1; shift ;;
      -h|--help) usage; exit 0 ;;
      *) die "Unknown option: $1" ;;
    esac
  done
}

ensure_flathub() {
  if ! flatpak remote-list --columns=name | grep -qx "flathub"; then
    say "Enabling Flathub…"
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  fi
}

install_apps() {
  say "Installing ${APP_MPV} and ${APP_VLC}…"
  flatpak install -y flathub "${APP_MPV}"
  flatpak install -y flathub "${APP_VLC}"
}

uninstall_apps() {
  say "Uninstalling ${APP_MPV} and ${APP_VLC}…"
  flatpak uninstall -y --noninteractive "${APP_MPV}" || true
  flatpak uninstall -y --noninteractive "${APP_VLC}" || true
}

reset_overrides() {
  say "Resetting overrides…"
  flatpak override --reset "${APP_MPV}" || true
  flatpak override --reset "${APP_VLC}" || true
}

apply_overrides() {
  # Base filesystem permissions
  FS_FLAG="--filesystem=${MEDIA_PATH}:ro"
  [ "$WRITE_ACCESS" -eq 1 ] && FS_FLAG="--filesystem=${MEDIA_PATH}:rw"

  say "Granting ${APP_MPV} ${FS_FLAG}…"
  flatpak override "${APP_MPV}" "${FS_FLAG}"
  say "Granting ${APP_VLC} ${FS_FLAG}…"
  flatpak override "${APP_VLC}" "${FS_FLAG}"

  # Capture devices if requested
  if [ "$CAPTURE" -eq 1 ]; then
    say "Allowing capture/GPU devices inside sandbox (device=all)…"
    flatpak override "${APP_MPV}" --device=all
    flatpak override "${APP_VLC}" --device=all
  fi

  # Strict sandbox for mpv
  if [ "$STRICT" -eq 1 ]; then
    say "Applying strict sandbox to ${APP_MPV}…"
    # Remove home, allow only DRI device + media path + portals
    flatpak override "${APP_MPV}" \
      --nofilesystem=home \
      --device=dri \
      --talk-name=org.freedesktop.portal.Desktop \
      --talk-name=org.freedesktop.portal.MemoryMonitor \
      --talk-name=org.freedesktop.portal.FileChooser \
      --filesystem="${MEDIA_PATH}:$( [ "$WRITE_ACCESS" -eq 1 ] && echo rw || echo ro )"
  fi
}

create_wrappers() {
  BIN_DIR="${HOME}/.local/bin"
  mkdir -p "${BIN_DIR}"

  # mpv wrapper
  MPV_WRAPPER="${BIN_DIR}/mpv"
  cat > "${MPV_WRAPPER}" <<EOF
#!/bin/sh
exec flatpak run ${APP_MPV} "\$@"
EOF
  chmod +x "${MPV_WRAPPER}"
  say "Created wrapper: ${MPV_WRAPPER}"

  # vlc wrapper
  VLC_WRAPPER="${BIN_DIR}/vlc"
  cat > "${VLC_WRAPPER}" <<EOF
#!/bin/sh
exec flatpak run ${APP_VLC} "\$@"
EOF
  chmod +x "${VLC_WRAPPER}"
  say "Created wrapper: ${VLC_WRAPPER}"

  case ":${PATH}:" in
    *:"${BIN_DIR}":*) : ;;
    *) err "NOTE: ${BIN_DIR} is not in PATH. Add it to your shell config." ;;
  esac
}

set_mime_defaults() {
  say "Setting default apps for common video types…"
  # mpv as default for local files
  xdg-mime default "${APP_MPV}.desktop" video/mp4
  xdg-mime default "${APP_MPV}.desktop" video/x-matroska
  xdg-mime default "${APP_MPV}.desktop" video/x-msvideo
  xdg-mime default "${APP_MPV}.desktop" video/webm
  # vlc for HLS playlists
  xdg-mime default "${APP_VLC}.desktop" video/x-mpegurl || true
}

show_summary() {
  say ""
  say "Done."
  say ""
  say "Effective permissions (mpv):"
  flatpak info --show-permissions "${APP_MPV}" || true
  say ""
  say "Effective permissions (VLC):"
  flatpak info --show-permissions "${APP_VLC}" || true
  say ""
  say "Wrappers:"
  say "  ~/.local/bin/mpv -> flatpak run ${APP_MPV}"
  say "  ~/.local/bin/vlc -> flatpak run ${APP_VLC}"
  say ""
  say "Tip: re-run with --reset to clear overrides, or --uninstall to remove apps."
}

main() {
  parse_args "$@"

  need flatpak
  need xdg-mime

  if [ "$UNINSTALL" -eq 1 ]; then
    uninstall_apps
    exit 0
  fi

  if [ "$RESET" -eq 1 ]; then
    reset_overrides
    exit 0
  fi

  if [ "$WRAPPER_ONLY" -eq 0 ]; then
    ensure_flathub
    install_apps
    apply_overrides
  fi

  create_wrappers
  if [ "$NO_MIME" -eq 0 ]; then
    set_mime_defaults
  fi
  show_summary
}

main "$@"
