#!/bin/sh
#MISE description="Add Flatpak repo definition"
#MISE hide=true
#USAGE arg "<url>" help="Flatpak URL"
#USAGE arg "[name]" help="Flatpak name (defaults to .flatpakrepo filename)"

set -eu

repo_url=${usage_url:?}
repo_name=${usage_name:-$(basename "${repo_url%%\?*}" .flatpakrepo)}

command -v flatpak >/dev/null 2>&1 || exit 0

flatpak remote-add --user --if-not-exists "$repo_name" "$repo_url"
