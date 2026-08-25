#!/bin/sh
#MISE description="Install a Fedora COPR repository definition"
#MISE hide=true
#USAGE arg "<project>" help="COPR project as OWNER/PROJECT"

set -eu

copr_project=${usage_project:?}

[ "$(uname -s)" = "Linux" ] || exit 0
[ -f /etc/os-release ] || exit 0
. /etc/os-release
[ "${ID:-}" = "fedora" ] || exit 0
[ -n "${VERSION_ID:-}" ] || exit 1

if command -v rpm-ostree >/dev/null 2>&1 && rpm-ostree status >/dev/null 2>&1; then
  :
elif command -v dnf >/dev/null 2>&1; then
  :
else
  exit 0
fi

copr_owner=${copr_project%%/*}
copr_repo=${copr_project#*/}

if [ "$copr_owner" = "$copr_project" ] || [ "$copr_repo" != "${copr_repo#*/}" ]; then
  echo "COPR project must be OWNER/PROJECT" >&2
  exit 2
fi

case "$copr_owner/$copr_repo" in
  *[!ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789._/-]* | */ | /*)
    echo "invalid COPR project: $copr_project" >&2
    exit 2
    ;;
esac

repo_filename="$copr_owner-$copr_repo-fedora-$VERSION_ID.repo"
repo_url="https://copr.fedorainfracloud.org/coprs/$copr_owner/$copr_repo/repo/fedora-$VERSION_ID/$repo_filename"

exec mise run bootstrap:rpm:repo-add "$repo_url" "$repo_filename"
