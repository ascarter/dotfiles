# lib/tool.sh — sourced library for tool installer scripts
#
# Source this file from tool scripts in tools/:
#   : "${DOTFILES_HOME:=$(cd "$(dirname "$0")/.." && pwd)}"
#   source "${DOTFILES_HOME}/lib/tool.sh"
#
# No shebang — this file is sourced, not executed.
# Does not use set -e internally; callers may set it.

# XDG base dirs with ~/.local fallbacks
: "${XDG_DATA_HOME:=$HOME/.local/share}"
: "${XDG_CACHE_HOME:=$HOME/.cache}"
: "${XDG_STATE_HOME:=$HOME/.local/state}"
: "${XDG_BIN_HOME:=$HOME/.local/bin}"

# Tool storage layout
TOOLS_HOME="${XDG_DATA_HOME}/tools"
TOOLS_CACHE="${XDG_CACHE_HOME}/tools"
TOOLS_STATE="${XDG_STATE_HOME}/tools"
TOOLS_BIN="${TOOLS_HOME}/bin"
TOOLS_SHARE="${TOOLS_HOME}/share"

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
mkdir -p "${TOOLS_HOME}" "${TOOLS_CACHE}" "${TOOLS_STATE}" "${TOOLS_BIN}" "${TOOLS_SHARE}"

# tool_latest_tag <owner/repo>
# Prints the latest release tag for the given repo.
tool_latest_tag() {
  local repo="$1"
  gh release list --repo "$repo" --limit 1 --json tagName --jq '.[0].tagName'
}

# tool_installed_tag <owner/repo>
# Reads the state file for owner/repo. Prints tag or "none".
tool_installed_tag() {
  local repo="$1"
  local state_key="${repo//\//_}"
  local state_file="${TOOLS_STATE}/${state_key}"
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
#   TOOLS_INSTALL_DIR  — versioned install directory
#   TOOLS_INSTALL_TAG  — resolved tag
#
# Handles:
#   .tar.gz  — tar -xzf to versioned dir
#   .zip     — unzip to versioned dir
#   .gz      — gunzip to plain binary in versioned dir (non-tar)
#   <no ext> — copy binary + chmod +x
#
# On macOS, strips quarantine attribute after extraction.
tool_gh_install() {
  local repo="$1"
  local asset_glob="$2"
  local tag="${3:-}"
  local owner="${repo%%/*}"
  local name="${repo##*/}"
  local state_key="${repo//\//_}"
  local state_file="${TOOLS_STATE}/${state_key}"

  # Resolve tag if not provided
  if [[ -z "$tag" ]]; then
    tag="$(tool_latest_tag "$repo")" || { printf 'tool_gh_install: failed to resolve tag for %s\n' "$repo" >&2; return 1; }
  fi

  if [[ -z "$tag" ]]; then
    printf 'tool_gh_install: could not determine tag for %s\n' "$repo" >&2
    return 1
  fi

  TOOLS_INSTALL_DIR="${TOOLS_HOME}/${owner}/${name}/${tag}"
  TOOLS_INSTALL_TAG="$tag"
  export TOOLS_INSTALL_DIR TOOLS_INSTALL_TAG

  # Skip if already installed at this tag
  local installed_tag
  installed_tag="$(tool_installed_tag "$repo")"
  if [[ "$installed_tag" == "$tag" && -d "$TOOLS_INSTALL_DIR" ]]; then
    printf '%s already at %s\n' "$repo" "$tag"
    return 0
  fi

  local cache_dir="${TOOLS_CACHE}/${owner}/${name}"
  mkdir -p "$cache_dir" "$TOOLS_INSTALL_DIR"

  # Download asset
  printf 'Downloading %s %s ...\n' "$repo" "$tag"
  gh release download "$tag" \
    --repo "$repo" \
    --pattern "$asset_glob" \
    --dir "$cache_dir" \
    --clobber || { printf 'tool_gh_install: download failed for %s %s\n' "$repo" "$tag" >&2; return 1; }

  # Find the downloaded file
  local asset_file
  asset_file="$(find "$cache_dir" -maxdepth 1 -name "$asset_glob" | head -n1)"
  if [[ -z "$asset_file" ]]; then
    printf 'tool_gh_install: no asset matching %s found in %s\n' "$asset_glob" "$cache_dir" >&2
    return 1
  fi

  # Extract based on format
  local filename
  filename="$(basename "$asset_file")"

  if [[ "$filename" == *.tar.gz || "$filename" == *.tgz ]]; then
    tar -xzf "$asset_file" -C "$TOOLS_INSTALL_DIR" || { printf 'tool_gh_install: tar extraction failed\n' >&2; return 1; }
  elif [[ "$filename" == *.zip ]]; then
    unzip -q -o "$asset_file" -d "$TOOLS_INSTALL_DIR" || { printf 'tool_gh_install: unzip extraction failed\n' >&2; return 1; }
  elif [[ "$filename" == *.gz ]]; then
    # Non-tar gzip: decompress to a binary named after the repo
    local out_name="${name}"
    gunzip -c "$asset_file" > "${TOOLS_INSTALL_DIR}/${out_name}" || { printf 'tool_gh_install: gunzip failed\n' >&2; return 1; }
    chmod +x "${TOOLS_INSTALL_DIR}/${out_name}"
  else
    # Plain binary: copy and make executable
    cp "$asset_file" "${TOOLS_INSTALL_DIR}/${filename}" || { printf 'tool_gh_install: copy failed\n' >&2; return 1; }
    chmod +x "${TOOLS_INSTALL_DIR}/${filename}"
  fi

  # Strip quarantine on macOS (unsigned binaries from GitHub releases)
  if [[ "$(uname -s)" == Darwin ]]; then
    printf 'Stripping quarantine attribute: %s\n' "$TOOLS_INSTALL_DIR"
    xattr -dr com.apple.quarantine "$TOOLS_INSTALL_DIR" 2>/dev/null || true
  fi

  # Record installed tag
  printf '%s\n' "$tag" > "$state_file"
  printf 'Installed %s %s -> %s\n' "$repo" "$tag" "$TOOLS_INSTALL_DIR"
}

# tool_link <src> <dst>
#
# Creates a symlink: TOOLS_HOME/<dst> -> TOOLS_INSTALL_DIR/<src>
# src is relative to TOOLS_INSTALL_DIR.
# dst is relative to TOOLS_HOME.
tool_link() {
  local src="$1"
  local dst="$2"
  local src_path="${TOOLS_INSTALL_DIR}/${src}"
  local dst_path="${TOOLS_HOME}/${dst}"

  mkdir -p "$(dirname "$dst_path")"
  ln -sf "$src_path" "$dst_path"
}
