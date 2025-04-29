#!/bin/sh

set -eu

odin_dir="${XDG_DATA_HOME}/odin"

install() {
  case $(uname -s) in
  Linux*)
    os="linux"
    ;;
  Darwin*)
    os="macos"
    ;;
  *)
    echo "Unsupported OS" >&2
    exit 1
    ;;
  esac

  case $(uname -m) in
  x86_64)
    arch="amd64"
    ;;
  aarch64 | arm64)
    arch="arm64"
    ;;
  *)
    echo "Unsupported architecture" >&2
    exit 1
    ;;
  esac

  ODIN_RELEASES_URL="https://api.github.com/repos/odin-lang/odin/releases/latest"

  jq_filter='{ tag: .tag_name, zip_url: .zipball_url } | [ .tag, .zip_url ] | @tsv'
  read -r tag zip_url <<EOF
    $(curl -fsSL "$ODIN_RELEASES_URL" | jq -r "$jq_filter")
EOF

  # Verify tag found
  if [ -z "$tag" ] || [ -z "$zip_url" ]; then
    echo "No matching stable release found for '${os}-${arch}'" >&2
    exit 1
  fi

  # Check if existing Odin install matches current stable
  if [ -d $odin_dir ]; then
    case $(odin version | cut -d' ' -f3) in
    "$tag"*)
      echo "Odin installed is latest version $tag"
      exit 0
      ;;
    esac
  fi

  # Download archive
  tmpfile=$(mktemp)
  trap 'rm -f "$tmpfile"' EXIT

  download_url="https://github.com/odin-lang/odin/releases/download/${tag}/odin-${os}-${arch}-${tag}.zip"
  echo "Downloading $download_url"
  curl -fsSL -o "$tmpfile" "$download_url"

  # Uninstall existing Odin install
  uninstall

  # Extract archive
  mkdir -p "$odin_dir"
  echo "$tmpfile"
  unzip -p "$tmpfile" | tar -xzf - -C "$odin_dir" --strip-components=1

  # Symlink zig
  ln -s $odin_dir/odin $LOCAL_BIN_HOME/odin

  echo "Odin ${tag} installed to $odin_dir"
}

uninstall() {
  if ! [ -d $odin_dir ]; then
    echo "Odin is not installed"
    return
  fi

  # Unlink binary
  odin_bin=${LOCAL_BIN_HOME}/odin
  if [ -L ${odin_bin} ]; then
    echo "unlink ${odin_bin}"
    rm ${odin_bin}
  fi

  echo "Removing existing Odin installation at $odin_dir"
  rm -rf "$odin_dir"
}

info() {
  if [ -d $odin_dir ]; then
    odin version
  else
    echo "Odin is not installed"
  fi
}

doctor() {
  info
}
