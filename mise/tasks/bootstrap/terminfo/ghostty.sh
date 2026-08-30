#!/bin/sh
#MISE description="Install the xterm-ghostty terminfo entry on Fedora"
#MISE hide=true

set -eu

[ "$(uname -s)" = "Linux" ] || exit 0
[ -f /etc/os-release ] || exit 0
. /etc/os-release
[ "${ID:-}" = "fedora" ] || exit 0

command -v infocmp >/dev/null 2>&1 || exit 0
command -v tic >/dev/null 2>&1 || exit 0

if infocmp -x xterm-ghostty >/dev/null 2>&1; then
  exit 0
fi

if ! infocmp -x ghostty >/dev/null 2>&1; then
  echo "ghostty terminfo entry is unavailable; install ncurses-term" >&2
  exit 1
fi

# Fedora's ncurses-term currently provides the Ghostty capabilities under the
# primary name "ghostty" only. Recompile that packaged definition under the
# TERM name emitted by Ghostty, without replacing the packaged ghostty entry.
terminfo_dir="$HOME/.terminfo"
mkdir -p "$terminfo_dir"

infocmp -x ghostty |
  awk '
    /^#/ || renamed { print; next }
    {
      sub(/^[^|,]+/, "xterm-ghostty")
      print
      renamed = 1
    }
  ' |
  tic -x -o "$terminfo_dir" -

TERMINFO="$terminfo_dir" infocmp -x xterm-ghostty >/dev/null
