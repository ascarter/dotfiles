# lib/opt.sh — sourced library for tool installer scripts
#
# Source this file from tool scripts in tools/:
#   : "${DOTFILES_HOME:=$(cd "$(dirname "$0")/.." && pwd)}"
#   source "${DOTFILES_HOME}/lib/opt.sh"
#
# No shebang — this file is sourced, not executed.
# Does not use set -e internally; callers may set it.

# Load shared display/logging functions (idempotent)
source "${DOTFILES_HOME}/lib/core.sh"

# XDG base dirs with ~/.local fallbacks
: "${XDG_DATA_HOME:=$HOME/.local/share}"
: "${XDG_CACHE_HOME:=$HOME/.cache}"
: "${XDG_STATE_HOME:=$HOME/.local/state}"
: "${XDG_BIN_HOME:=$HOME/.local/bin}"
: "${XDG_OPT_HOME:=$HOME/.local/opt}"
: "${XDG_OPT_BIN:=$XDG_OPT_HOME/bin}"
: "${XDG_OPT_SHARE:=$XDG_OPT_HOME/share}"
export XDG_OPT_HOME XDG_OPT_BIN XDG_OPT_SHARE

# Tool storage layout
#
# XDG_OPT_HOME (~/.local/opt)
#   bin/          (XDG_OPT_BIN)  symlink farm for binaries
#   share/        (XDG_OPT_SHARE) symlink farm for man pages and completions
#   cellar/       (TOOLS_CELLAR)  versioned installs, keyed by tool name
#     <name>/
#       <tag>/    extracted assets
#
# XDG_CACHE_HOME/tools/  (TOOLS_CACHE)  downloaded archives, keyed by tool name
#   <name>/
#
# XDG_STATE_HOME/tools/  (TOOLS_STATE)  installed version receipts
#   <name>        one file per tool, contains the installed tag
#
TOOLS_CELLAR="${XDG_OPT_HOME}/cellar"
TOOLS_CACHE="${XDG_CACHE_HOME}/tools"
TOOLS_STATE="${XDG_STATE_HOME}/tools"
# Convenience aliases used by tool scripts
TOOLS_BIN="${XDG_OPT_BIN}"
TOOLS_SHARE="${XDG_OPT_SHARE}"

# Detect platform: <arch>-<os>
# Produces: aarch64-darwin, x86_64-darwin, aarch64-linux, x86_64-linux
_tool_detect_platform() {
  local arch os
  arch="$(uname -m)"
  case "$(uname -s)" in
    Darwin) os="darwin" ;;
    Linux)  os="linux"  ;;
    *)      os="unknown" ;;
  esac
  case "$arch" in
    arm64) arch="aarch64" ;;
  esac
  printf '%s-%s\n' "$arch" "$os"
}

TOOLS_PLATFORM="$(_tool_detect_platform)"
export TOOLS_PLATFORM

# Ensure required directories exist
mkdir -p "${TOOLS_CELLAR}" "${TOOLS_CACHE}" "${TOOLS_STATE}" "${TOOLS_BIN}" "${TOOLS_SHARE}"

# tool_check <cmd>
#
# Call at the top of a tool script to skip if the tool is already installed.
# During upgrade (DOTFILES_TOOL_UPGRADE=1), always continues so the script
# can re-evaluate versions.
# Exits 0 (skip) if the command is found and this is not an upgrade.
tool_check() {
  local cmd="$1"
  if [[ -n "${DOTFILES_TOOL_UPGRADE:-}" ]]; then
    return 0
  fi
  if command -v "$cmd" >/dev/null 2>&1; then
    log "skip" "${cmd} already installed: $(command -v "$cmd")"
    exit 0
  fi
}

# tool_latest_tag <owner/repo>
# Prints the latest release tag for the given repo.
tool_latest_tag() {
  local repo="$1"
  gh release list --repo "$repo" --limit 1 --json tagName --jq '.[0].tagName'
}

# tool_installed_tag <owner/repo>
# Reads the state file for the tool. Prints tag or "none".
tool_installed_tag() {
  local repo="$1"
  local name="${repo##*/}"
  local state_file="${TOOLS_STATE}/${name}"
  if [[ -f "$state_file" ]]; then
    cat "$state_file"
  else
    printf 'none\n'
  fi
}

# tool_gh_install <owner/repo> <asset-glob> [tag]
#
# Downloads and extracts a GitHub release asset.
# After completion, sets:
#   TOOLS_INSTALL_DIR  — versioned install directory (TOOLS_CELLAR/<name>/<tag>/)
#   TOOLS_INSTALL_TAG  — resolved tag
#
# Handles:
#   .tar.gz  — tar -xzf to versioned dir
#   .zip     — unzip to versioned dir
#   .gz      — gunzip to plain binary in versioned dir (non-tar)
#   <no ext> — copy binary + chmod +x
tool_gh_install() {
  local repo="$1"
  local asset_glob="$2"
  local tag="${3:-}"
  local name="${repo##*/}"
  local state_file="${TOOLS_STATE}/${name}"

  # Resolve tag if not provided
  if [[ -z "$tag" ]]; then
    tag="$(tool_latest_tag "$repo")" || { error "tool_gh_install: failed to resolve tag for ${repo}"; return 1; }
  fi

  if [[ -z "$tag" ]]; then
    error "tool_gh_install: could not determine tag for ${repo}"
    return 1
  fi

  TOOLS_INSTALL_DIR="${TOOLS_CELLAR}/${name}/${tag}"
  TOOLS_INSTALL_TAG="$tag"
  export TOOLS_INSTALL_DIR TOOLS_INSTALL_TAG

  # Skip if already installed at this tag
  local installed_tag
  installed_tag="$(tool_installed_tag "$repo")"
  if [[ "$installed_tag" == "$tag" && -d "$TOOLS_INSTALL_DIR" ]]; then
    log "skip" "${name} already at ${tag}"
    return 0
  fi

  local cache_dir="${TOOLS_CACHE}/${name}"
  mkdir -p "$cache_dir" "$TOOLS_INSTALL_DIR"

  # Download asset
  log "download" "${repo} ${tag}"
  gh release download "$tag" \
    --repo "$repo" \
    --pattern "$asset_glob" \
    --dir "$cache_dir" \
    --clobber || { error "tool_gh_install: download failed for ${repo} ${tag}"; return 1; }

  # Find the downloaded file
  local asset_file
  asset_file="$(find "$cache_dir" -maxdepth 1 -name "$asset_glob" | head -n1)"
  if [[ -z "$asset_file" ]]; then
    error "tool_gh_install: no asset matching ${asset_glob} found in ${cache_dir}"
    return 1
  fi

  # Extract based on format
  local filename
  filename="$(basename "$asset_file")"

  if [[ "$filename" == *.tar.gz || "$filename" == *.tgz ]]; then
    tar -xzf "$asset_file" -C "$TOOLS_INSTALL_DIR" || { error "tool_gh_install: tar extraction failed"; return 1; }
  elif [[ "$filename" == *.zip ]]; then
    unzip -q -o "$asset_file" -d "$TOOLS_INSTALL_DIR" || { error "tool_gh_install: unzip extraction failed"; return 1; }
  elif [[ "$filename" == *.gz ]]; then
    # Non-tar gzip: decompress to a binary named after the tool
    gunzip -c "$asset_file" > "${TOOLS_INSTALL_DIR}/${name}" || { error "tool_gh_install: gunzip failed"; return 1; }
    chmod +x "${TOOLS_INSTALL_DIR}/${name}"
  else
    # Plain binary: copy and make executable
    cp "$asset_file" "${TOOLS_INSTALL_DIR}/${filename}" || { error "tool_gh_install: copy failed"; return 1; }
    chmod +x "${TOOLS_INSTALL_DIR}/${filename}"
  fi

  # Record installed tag
  printf '%s\n' "$tag" > "$state_file"
  log "install" "${name} ${tag} -> ${TOOLS_INSTALL_DIR}"
}

# tool_strip_quarantine <path>
#
# Strips com.apple.quarantine from an unsigned binary on macOS.
# No-op on Linux or when the binary is already code-signed.
tool_strip_quarantine() {
  [[ "$(uname -s)" == Darwin ]] || return 0
  local target="${1:-}"
  [[ -n "$target" && -f "$target" ]] || { error "tool_strip_quarantine: path required"; return 1; }

  if codesign -d "$target" >/dev/null 2>&1; then
    log "quarantine" "already signed: ${target}"
    return 0
  fi

  log "quarantine" "stripping com.apple.quarantine: ${target}"
  xattr -dr com.apple.quarantine "$target" 2>/dev/null || true
}

# tool_link <src> <dst>
#
# Creates a symlink: XDG_OPT_HOME/<dst> -> TOOLS_INSTALL_DIR/<src>
# src is relative to TOOLS_INSTALL_DIR.
# dst is relative to XDG_OPT_HOME (e.g. "bin/rg", "share/man/man1/rg.1").
tool_link() {
  local src="$1"
  local dst="$2"
  local src_path="${TOOLS_INSTALL_DIR}/${src}"
  local dst_path="${XDG_OPT_HOME}/${dst}"

  mkdir -p "$(dirname "$dst_path")"
  ln -sf "$src_path" "$dst_path"
}
