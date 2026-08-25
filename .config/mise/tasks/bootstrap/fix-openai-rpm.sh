#!/bin/sh
#MISE description="Repair the OpenAI RPM OpenPGP key when needed"
#MISE hide=true
#MISE interactive=true

set -eu

[ "$(uname -s)" = "Linux" ] || exit 0

key=/etc/pki/rpm-gpg/RPM-GPG-KEY-chatgpt
armored_key="$key.asc"

[ -r "$key" ] || exit 0

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT HUP INT TERM

if [ -r "$armored_key" ] &&
  gpg --dearmor < "$armored_key" > "$tmp" &&
  cmp -s "$tmp" "$key"; then
  exit 0
fi

gpg --enarmor < "$key" > "$tmp"
sudo install -o root -g root -m 0644 "$tmp" "$armored_key"
