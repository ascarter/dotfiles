#!/bin/sh
# camera-preview.sh — portable webcam preview (macOS avfoundation, Linux v4l2)

set -eu

OS="$(uname -s)"
PLAYER="${PLAYER:-mpv}"         # mpv | ffplay
FMT="${FMT:-y4m}"               # y4m | raw
FPS="${FPS:-30}"
SIZE="${SIZE:-1280x720}"
DEVICE=""
LIST_ONLY=0

print_usage() {
  cat <<EOF
Usage: ${0##*/} [options]

Options:
  --list                     List cameras (backend-specific) and exit
  --device <id|path>         macOS: numeric index (e.g. 0) ; Linux: /dev/videoN
  --size <WxH>               Desired output size (default: ${SIZE})
  --fps <num>                Desired output fps (default: ${FPS})
  --format <y4m|raw>         Output pipe format to the player (default: ${FMT})
  --player <mpv|ffplay>      Player (default: ${PLAYER})
  --help                     Show this help

Environment:
  PLAYER=mpv|ffplay   FMT=y4m|raw   FPS=NN   SIZE=WxH

Examples:
  ${0##*/} --device 0 --size 1280x720 --fps 30
  ${0##*/} --list
EOF
}

err() { printf '%s\n' "$*" >&2; }
have() { command -v "$1" >/dev/null 2>&1; }

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --list) LIST_ONLY=1 ;;
      --device) shift; DEVICE="${1:-}"; [ -n "${DEVICE}" ] || { err "Missing value for --device"; exit 2; } ;;
      --size) shift; SIZE="${1:-}"; [ -n "${SIZE}" ] || { err "Missing value for --size"; exit 2; } ;;
      --fps) shift; FPS="${1:-}"; [ -n "${FPS}" ] || { err "Missing value for --fps"; exit 2; } ;;
      --format) shift; FMT="${1:-}"; [ -n "${FMT}" ] || { err "Missing value for --format"; exit 2; } ;;
      --player) shift; PLAYER="${1:-}"; [ -n "${PLAYER}" ] || { err "Missing value for --player"; exit 2; } ;;
      --raw) FMT="raw" ;;
      --help|-h) print_usage; exit 0 ;;
      --) shift; break ;;
      -*) err "Unknown option: $1"; print_usage; exit 2 ;;
      *) : ;;
    esac
    shift
  done
}

list_devices_macos() {
  if ! have ffmpeg; then err "ffmpeg is required to list devices on macOS."; exit 1; fi
  ffmpeg -hide_banner -f avfoundation -list_devices true -i "" 2>&1 | awk '
    /AVFoundation video devices:/ {vid=1; aud=0; next}
    /AVFoundation audio devices:/ {vid=0; aud=1; next}
    vid && /\[[0-9]+\]/ {print "Video " $0}
    aud && /\[[0-9]+\]/ {print "Audio " $0}
  '
}

list_devices_linux() {
  if have v4l2-ctl; then v4l2-ctl --list-devices 2>/dev/null || true; fi
  ls -1 /dev/video* 2>/dev/null || true
}

list_devices() {
  case "$OS" in
    Darwin) list_devices_macos ;;
    Linux)  list_devices_linux ;;
    *) err "Unsupported OS for --list: $OS"; exit 1 ;;
  esac
}

build_ffmpeg_input() {
  case "$OS" in
    Darwin)
      INDEV="avfoundation"
      [ -n "$DEVICE" ] || DEVICE="0"  # default to first camera
      IN_FMT_OPTS="-pixel_format nv12 -framerate $FPS -video_size $SIZE"
      IN_SPEC="$DEVICE"
      ;;
    Linux)
      INDEV="video4linux2"
      if [ -z "$DEVICE" ]; then
        DEVICE="$(ls -1 /dev/video* 2>/dev/null | head -n1 || true)"
        [ -n "$DEVICE" ] || { err "No V4L2 device found. Provide --device /dev/videoN"; exit 1; }
      fi
      IN_FMT_OPTS="-framerate $FPS"
      IN_SPEC="$DEVICE"
      ;;
    *)
      err "Unsupported OS: $OS"; exit 1 ;;
  esac

  # No -start_at_zero here (caused the stray '1' issue). Keep latency-friendly flags.
  printf '%s\n' "-hide_banner -fflags nobuffer+genpts -flags low_delay -thread_queue_size 256 -use_wallclock_as_timestamps 1 -f $INDEV $IN_FMT_OPTS -an -i $IN_SPEC"
}

build_ffmpeg_filters_and_mux() {
  case "$FMT" in
    y4m)
      printf '%s\n' "-vf setsar=1,fps=$FPS,scale=${SIZE}:flags=fast_bilinear -f yuv4mpegpipe -pix_fmt yuv420p -"
      ;;
    raw)
      printf '%s\n' "-vf setsar=1,fps=$FPS,scale=${SIZE}:flags=fast_bilinear,format=nv12 -f rawvideo -pix_fmt nv12 -"
      ;;
    *)
      err "Unknown format: $FMT (use y4m|raw)"; exit 2 ;;
  esac
}

run_player() {
  case "$PLAYER" in
    mpv)
      if [ "$FMT" = "y4m" ]; then
        exec mpv --no-config --profile=low-latency --untimed --demuxer-thread=no - 2>/dev/null
      else
        W="${SIZE%x*}"; H="${SIZE#*x}"
        exec mpv --no-config --profile=low-latency --untimed --demuxer-thread=no \
             --demuxer=rawvideo \
             --demuxer-rawvideo-w="$W" \
             --demuxer-rawvideo-h="$H" \
             --demuxer-rawvideo-format=nv12 \
             --demuxer-rawvideo-fps="$FPS" \
             - 2>/dev/null
      fi
      ;;
    ffplay)
      if [ "$FMT" = "y4m" ]; then
        exec ffplay -hide_banner -fflags nobuffer -flags low_delay -framedrop -sync video \
             -f yuv4mpegpipe -i -
      else
        W="${SIZE%x*}"; H="${SIZE#*x}"
        exec ffplay -hide_banner -fflags nobuffer -flags low_delay -framedrop -sync video \
             -f rawvideo -pixel_format nv12 -video_size "${W}x${H}" -framerate "$FPS" -i -
      fi
      ;;
    *)
      err "Unknown player: $PLAYER (use mpv|ffplay)"; exit 2 ;;
  esac
}

main() {
  parse_args "$@"

  if [ "$LIST_ONLY" -eq 1 ]; then
    list_devices
    exit 0
  fi

  have ffmpeg || { err "ffmpeg is required."; exit 1; }
  have "$PLAYER" || { err "Player '$PLAYER' not found on PATH."; exit 1; }

  IN_ARGS="$(build_ffmpeg_input)"
  OUT_ARGS="$(build_ffmpeg_filters_and_mux)"

  # shellcheck disable=SC2086
  eval "ffmpeg $IN_ARGS $OUT_ARGS" | run_player
}

main "$@"
