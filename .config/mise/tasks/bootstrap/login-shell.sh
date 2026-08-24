#!/bin/sh
#MISE description="Set the login shell when available"
#MISE interactive=true
#USAGE arg "[shell]" help="Absolute login-shell path" default="/bin/zsh"

set -eu

login_shell=${usage_shell:?}

case "$login_shell" in
  /*) ;;
  *)
    printf '%s\n' "Login shell must be an absolute path: $login_shell" >&2
    exit 2
    ;;
esac

if [ ! -x "$login_shell" ]; then
  printf '%s\n' "$login_shell is not available; if rpm-ostree staged it, reboot and rerun mise bootstrap."
  exit 0
fi

case "$(uname -s)" in
  Darwin)
    current_shell="$(dscl . -read "/Users/$(id -un)" UserShell 2>/dev/null | awk '{print $2}')"
    ;;
  Linux)
    current_shell="$(getent passwd "$(id -un)" | awk -F: '{print $7}')"
    ;;
  *)
    exit 0
    ;;
esac

[ "$current_shell" = "$login_shell" ] && exit 0

if ! grep -Fxq "$login_shell" /etc/shells; then
  printf '%s\n' "$login_shell is not an approved login shell; install or configure it before rerunning mise bootstrap." >&2
  exit 1
fi

chsh -s "$login_shell"
