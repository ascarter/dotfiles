#!/bin/sh
#MISE description="Install an RPM repository definition"
#MISE hide=true
#USAGE arg "<url>" help="Repository definition URL"
#USAGE arg "[filename]" help="Destination filename (defaults to URL basename)"
#USAGE flag "--dir <dir>" default="/etc/yum.repos.d"

set -eu

repo_url=${usage_url:?}
repo_filename=${usage_filename:-$(basename "${repo_url%%\?*}")}
repo_dir=${usage_dir:-/etc/yum.repos.d}
repo_file="$repo_dir/$repo_filename"

case "$repo_filename" in
  "" | . | .. | */*)
    echo "invalid repository filename: $repo_filename" >&2
    exit 2
    ;;
esac

[ "$(uname -s)" = "Linux" ] || exit 0
[ -f /etc/os-release ] || exit 0
. /etc/os-release
[ "${ID:-}" = "fedora" ] || exit 0

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

curl -fsSL -o "$tmp" "$repo_url"

if ! cmp -s "$tmp" "$repo_file" 2>/dev/null; then
  sudo install -o root -g root -m 0644 "$tmp" "$repo_file"
fi
