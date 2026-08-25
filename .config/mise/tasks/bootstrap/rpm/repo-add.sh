#!/bin/sh
#MISE description="Install an RPM repository definition"
#MISE hide=true
#USAGE arg "<source>" help="Repository definition URL or local path"
#USAGE arg "[filename]" help="Destination filename (defaults to URL basename)"

set -eu

repo_source=${usage_source:?}
repo_filename=${usage_filename:-$(basename "${repo_source%%\?*}")}
repo_dir=/etc/yum.repos.d
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

case "$repo_source" in
  https://* | http://*)
    curl -fsSL -o "$tmp" "$repo_source"
    ;;
  *)
    cp "$repo_source" "$tmp"
    ;;
esac

if ! cmp -s "$tmp" "$repo_file" 2>/dev/null; then
  sudo install -o root -g root -m 0644 "$tmp" "$repo_file"
fi
