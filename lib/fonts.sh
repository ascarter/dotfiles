# lib/fonts.sh — shared font installation helpers
#
# Sourced by per-font scripts under scripts/fonts/.
# No shebang — this file is sourced, not executed.
#
# Provides:
#   font_dir                       — platform user-font directory
#   font_cache_dir                 — download cache directory (created on demand)
#   font_refresh_cache             — refresh OS font cache (Linux only)
#   font_extract_archive           — extract matching files from zip or tar.gz
#   font_install_github_release    — download a GitHub release asset and install it
#
# Per-font scripts pin VERSION variables explicitly; this library does NO
# upstream version resolution and NO state tracking. Re-running a script
# re-downloads (cached) and re-extracts (overwrites identical bytes), which
# is cheap and keeps the helpers simple.

# Idempotent guard
[[ -n "${_DOTFILES_FONTS_LOADED:-}" ]] && return 0
_DOTFILES_FONTS_LOADED=1

# Echo the platform user-font directory.
font_dir() {
  case "$(uname -s)" in
    Darwin) echo "${HOME}/Library/Fonts" ;;
    Linux)  echo "${XDG_DATA_HOME:-${HOME}/.local/share}/fonts" ;;
    *) abort "Unsupported OS for font install: $(uname -s)" ;;
  esac
}

# Echo the font download cache directory, creating it on demand.
font_cache_dir() {
  local dir="${XDG_CACHE_HOME:-${HOME}/.cache}/dotfiles/fonts"
  mkdir -p "$dir"
  echo "$dir"
}

# Refresh the OS font cache. No-op on macOS (Font Book reads on next launch).
font_refresh_cache() {
  case "$(uname -s)" in
    Linux)
      if command -v fc-cache >/dev/null 2>&1; then
        fc-cache -f "$(font_dir)" >/dev/null 2>&1 || \
          warn "fonts" "fc-cache failed"
      fi
      ;;
  esac
}

# font_extract_archive <archive> <dest> <glob>...
#
# Extract files matching any of the given globs from <archive> into <dest>,
# flattened (no preserved directory structure). Excludes macOS ._* and
# __MACOSX/* cruft. Supports .zip and .tar.gz/.tgz.
#
# Globs are matched against archive-relative paths using bash globstar
# (e.g. "fonts/variable/*.ttf" or "**/*.otf"). Returns non-zero if no
# files match.
font_extract_archive() {
  local archive="$1" dest="$2"
  shift 2

  local tmpdir
  tmpdir=$(mktemp -d -t dotfiles-fonts.XXXXXXXX)
  # shellcheck disable=SC2064
  trap "rm -rf '$tmpdir'" RETURN

  case "$archive" in
    *.zip)
      unzip -qq -o "$archive" -x '._*' '__MACOSX/*' -d "$tmpdir" 2>/dev/null || {
        error "unzip failed: $archive"
        return 1
      }
      ;;
    *.tar.gz|*.tgz)
      tar -xzf "$archive" -C "$tmpdir" || {
        error "tar extract failed: $archive"
        return 1
      }
      ;;
    *)
      error "unsupported archive format: $archive"
      return 1
      ;;
  esac

  mkdir -p "$dest"

  # Match globs inside a subshell so shopt changes don't leak.
  # compgen -G expands a single glob pattern without word-splitting on
  # spaces (critical for archives like Monaspace whose paths contain
  # spaces). globstar is best-effort (not available in bash 3.2).
  local matched
  matched=$(
    shopt -s nullglob
    shopt -s globstar 2>/dev/null || true
    cd "$tmpdir" || exit 0
    for glob in "$@"; do
      while IFS= read -r f; do
        [ -f "$f" ] || continue
        printf '%s\n' "$f"
      done < <(compgen -G "$glob" 2>/dev/null || true)
    done
  )

  if [ -z "$matched" ]; then
    warn "fonts" "no files matched in $(basename "$archive")"
    return 1
  fi

  local count=0 f base
  while IFS= read -r f; do
    base="${f##*/}"
    cp "${tmpdir}/${f}" "${dest}/${base}"
    count=$((count + 1))
  done <<<"$matched"

  vlog "fonts" "extracted ${count} file(s) to ${dest}"
}

# font_install_github_release --name <n> --repo <r> --tag <t>
#                             --asset <pattern> --extract <glob>...
#                             [--dest-subdir <subdir>]
#
# Download a GitHub release asset matching <pattern> from <repo>@<tag>
# into the font cache, then extract files matching the <extract> globs
# into the platform font directory (or a subdirectory if --dest-subdir
# is given), and refresh the font cache.
#
# Required flags:
#   --name      Logical name for log output (e.g. jetbrains-mono).
#   --repo      GitHub owner/repo (e.g. JetBrains/JetBrainsMono).
#   --tag       Release tag (e.g. v2.304 or @ibm/plex-mono@1.1.0).
#   --asset     Asset filename or glob to pass to `gh release download --pattern`.
#   --extract   Glob (repeatable) of font files to extract from the asset.
#
# Optional flags:
#   --dest-subdir   Install into font_dir/<subdir>/ instead of font_dir/.
#                   Use when archive contains generic filenames that would
#                   collide with other fonts (e.g. IBM Plex Variable's
#                   Var-Roman.ttf).
font_install_github_release() {
  local name="" repo="" tag="" asset="" subdir=""
  local extracts=()

  while [ $# -gt 0 ]; do
    case "$1" in
      --name)        name="$2"; shift 2 ;;
      --repo)        repo="$2"; shift 2 ;;
      --tag)         tag="$2"; shift 2 ;;
      --asset)       asset="$2"; shift 2 ;;
      --extract)     extracts+=("$2"); shift 2 ;;
      --dest-subdir) subdir="$2"; shift 2 ;;
      *) error "font_install_github_release: unknown flag: $1"; return 2 ;;
    esac
  done

  [ -n "$name" ]   || { error "font_install_github_release: --name required"; return 2; }
  [ -n "$repo" ]   || { error "font_install_github_release: --repo required"; return 2; }
  [ -n "$tag" ]    || { error "font_install_github_release: --tag required"; return 2; }
  [ -n "$asset" ]  || { error "font_install_github_release: --asset required"; return 2; }
  [ ${#extracts[@]} -gt 0 ] || {
    error "font_install_github_release: at least one --extract required"
    return 2
  }

  command -v gh >/dev/null 2>&1 || abort "gh CLI required to install fonts"

  local cache dest
  cache="$(font_cache_dir)"
  dest="$(font_dir)"
  [ -n "$subdir" ] && dest="${dest}/${subdir}"

  # Cache key uses tag + asset filename to keep distinct versions side-by-side.
  local safe_tag="${tag//\//_}"
  local cached="${cache}/${name}-${safe_tag}-${asset##*/}"

  if [ ! -f "$cached" ]; then
    log "$name" "downloading ${repo}@${tag}"
    gh release download "$tag" \
      --repo "$repo" \
      --pattern "$asset" \
      --output "$cached" \
      --clobber \
      || { error "gh release download failed for ${repo}@${tag}"; rm -f "$cached"; return 1; }
  else
    vlog "$name" "using cached ${cached##*/}"
  fi

  log "$name" "installing to ${dest}"
  font_extract_archive "$cached" "$dest" "${extracts[@]}" || return 1
  font_refresh_cache
  return 0
}
