#!/bin/sh

set -eu

zig_dir="${XDG_DATA_HOME}/zig"

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
    arch="x86_64"
    ;;
  aarch64 | arm64)
    arch="aarch64"
    ;;
  *)
    echo "Unsupported architecture" >&2
    exit 1
    ;;
  esac

  ZIG_RELEASES_URL="https://ziglang.org/download/index.json"
  platform="${arch}-${os}"

  jq_filter='
    to_entries
    | map(
      select(
        .key != "master" and ( .key | test("-dev") | not))
      )
    | map (
      select(
        .value[$platform] != null
      )
    | {ver: .key} + (.value[$platform]
    | { tarball, shasum }))
    | max_by(.ver | split(".") | map(tonumber))
    | [.ver, .tarball, .shasum]
    | @tsv'

  read -r version tarball_url expected_sum <<EOF
    $(curl -fsSL "$ZIG_RELEASES_URL" | jq -r --arg platform "$platform" "$jq_filter")
EOF

  # Verify version found
  if [ -z "$version" ] || [ -z "$tarball_url" ] || [ -z "$expected_sum" ]; then
    echo "No matching stable release found for '$platform'" >&2
    exit 1
  fi

  # Check if existing Zig install matches current stable
  if [ -d $zig_dir ]; then
    if [ "$($zig_dir/zig version)" = "$version" ]; then
      echo "Zig installed is latest version $version"
      exit 0
    fi
  fi

  # Download archive
  tmpfile=$(mktemp)
  trap 'rm -f "$tmpfile"' EXIT

  echo "Downloading $tarball_url"
  curl -fsSL -o "$tmpfile" "$tarball_url"

  # Verify checksum
  if ! sha256 --quiet -c "$expected_sum" "$tmpfile"; then
    echo "Checksum verification failed" >&2
    exit 1
  fi

  # Uninstall existing Zig install
  uninstall

  # Extract archive
  mkdir -p "$zig_dir"
  case "$tarball_url" in
  *.tar.xz)
    tar -xJf "$tmpfile" --strip-components=1 -C "$zig_dir"
    ;;
  *)
    echo "Unsupported archive format: $tarball_url" >&2
    exit 1
    ;;
  esac

  # Symlink zig
  ln -s $zig_dir/zig $LOCAL_BIN_HOME/zig

  echo "Zig ${version} installed to $zig_dir"
}

uninstall() {
  if ! [ -d $zig_dir ]; then
    echo "Zig is not installed"
    return
  fi

  # Unlink binary
  zig_bin=${LOCAL_BIN_HOME}/zig
  if [ -L ${zig_bin} ]; then
    echo "unlink ${zig_bin}"
    rm ${zig_bin}
  fi

  echo "Removing existing Zig installation at $zig_dir"
  rm -rf "$zig_dir"
}

info() {
  if [ -d $zig_dir ]; then
    zig version
  else
    echo "Zig is not installed"
  fi
}

doctor() {
  if [ -d $zig_dir ]; then
    info
    zig env
  else
    echo "Zig is not installed"
  fi
}
