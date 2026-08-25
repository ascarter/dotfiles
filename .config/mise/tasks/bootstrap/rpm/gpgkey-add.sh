#!/bin/sh
#MISE description="Install an RPM repository signing key"
#MISE hide=true
#USAGE arg "<source>" help="Signing-key URL or local path"
#USAGE arg "[filename]" help="Destination filename (defaults to URL basename)"

set -eu

key_source=${usage_source:?}
key_filename=${usage_filename:-$(basename "${key_source%%\?*}")}
key_dir=/etc/pki/rpm-gpg
key_file="$key_dir/$key_filename"

case "$key_filename" in
  "" | . | .. | */*)
    echo "invalid signing-key filename: $key_filename" >&2
    exit 2
    ;;
esac

[ "$(uname -s)" = "Linux" ] || exit 0
[ -f /etc/os-release ] || exit 0
. /etc/os-release
[ "${ID:-}" = "fedora" ] || exit 0

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

case "$key_source" in
  https://* | http://*)
    curl -fsSL -o "$tmp" "$key_source"
    ;;
  *)
    cp "$key_source" "$tmp"
    ;;
esac

if ! cmp -s "$tmp" "$key_file" 2>/dev/null; then
  sudo install -o root -g root -m 0644 "$tmp" "$key_file"
fi
