#!/bin/sh
#MISE description="Install RPM package"
#MISE hide=true
#USAGE arg "<packages>..." help="RPM package names"
#USAGE flag "--url <url>" help="RPM package URL or local path (requires one package name)"

set -eu

rpm_url=${usage_url:-}

# usage encodes variadic values as shell-escaped words.
eval "set -- ${usage_packages:?}"

[ "$(uname -s)" = "Linux" ] || exit 0
command -v rpm >/dev/null 2>&1 || exit 0

if command -v rpm-ostree >/dev/null 2>&1 && rpm-ostree status >/dev/null 2>&1; then
  installer=rpm-ostree
elif command -v dnf >/dev/null 2>&1; then
  installer=dnf
else
  exit 0
fi

if [ -n "$rpm_url" ]; then
  if [ "$#" -ne 1 ]; then
    echo "--url requires exactly one package name" >&2
    exit 2
  fi

  if rpm -q --quiet "$1"; then
    echo "$1 is already installed"
    exit 0
  fi

  set -- "$rpm_url"
fi

case "$installer" in
  rpm-ostree)
    rpm-ostree install -y --idempotent "$@"
    ;;
  dnf)
    sudo dnf install -y "$@"
    ;;
esac
