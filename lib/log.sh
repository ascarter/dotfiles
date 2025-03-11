# Logging
log() {
  if [ "$#" -eq 1 ]; then
    printf "%s\n" "$1"
  elif [ "$#" -gt 1 ]; then
    printf "$(tput bold)%-10s$(tput sgr0)\t%s\n" "$1" "$2"
  fi
}

# title log
tlog() {
  log "  $1" "$2"
}

# detail log
dlog() {
  tlog "  $1" "$2"
}

# verbose log
vlog() {
  if [ $VERBOSE -eq 1 ]; then
    log "$@"
  fi
}

# error log
err() {
  echo "  $(tput bold)error     $(tput sgr0)\t$*" >&2
}

# warning log
warn() {
  echo "$(tput bold)$*$(tput sgr0)" >&2
}

# prompt user for confirmation
prompt() {
  choice=y
  read -p "$1 (y/N)" -n1 choice
  echo
  case $choice in
  [yY]*) return 0 ;;
  esac
  return 1
}
