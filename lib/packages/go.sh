#!/bin/sh

set -eu

GOROOT="$XDG_DATA_HOME/go"

install() {
  case $(uname -s) in
  Linux*)
    os="linux"
    ;;
  Darwin*)
    os="darwin"
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

  ext="tar.gz"
  GO_RELEASES_URL="https://go.dev/dl/?mode=json"
  jq_filter='
    .[0].files[]
    | select(
      .os == $os and .arch == $arch and (
        .filename | endswith($ext)
      )
    )
    | [.filename, .sha256, .version]
    | @tsv'

  read filename checksum version <<EOF
    $(curl -s "$GO_RELEASES_URL" | jq -r --arg os "$os" --arg arch "$arch" --arg ext "$ext" "$jq_filter")
EOF

  # Verify version found
  if [ -z "$version" ] || [ -z "$filename" ] || [ -z "$checksum" ]; then
    echo "No matching stable release found for '$arch-$os'" >&2
    exit 1
  fi

  # Check if existing Go install matches current stable
  if [ -d $GOROOT ]; then
    if [ "$($GOROOT/bin/go version)" = "go version $version $os/$arch" ]; then
      echo "Go installed is latest version $version"
      exit 0
    fi
  fi

  # Download to a temporary file
  tmpfile=$(mktemp)
  trap 'rm -f "$tmpfile"' EXIT

  download_url="https://go.dev/dl/$filename"
  echo "Downloading $download_url"
  curl -fsSL -o "$tmpfile" "$download_url"

  # Verify checksum
  if ! sha256 --quiet -c "$checksum" "$tmpfile"; then
    echo "Checksum verification failed." >&2
    exit 1
  fi

  # Uninstall existing Go install
  uninstall

  # Extract the archive
  tar -C "$XDG_DATA_HOME" -xzf "$tmpfile"

  # Symlink binaries
  for gobin in ${GOROOT}/bin/*; do
    bin="$LOCAL_BIN_HOME/${gobin##*/}"
    if ! [ -e $bin ]; then
      echo "link $gobin -> $bin"
      ln -s $gobin $bin
    fi
  done

  echo "Go ${version} installed to $XDG_DATA_HOME/go"
}

uninstall() {
  # Check if Go is installed
  if ! [ -d $GOROOT ]; then
    echo "Go is not installed"
    return
  fi

  # Unlink binaries
  for gobin in ${GOROOT}/bin/*; do
    bin="$LOCAL_BIN_HOME/${gobin##*/}"
    if [ -L $bin ]; then
      echo "unlink $bin"
      rm $bin
    fi
  done

  echo "Removing existing Go installation at $XDG_DATA_HOME/go"
  rm -rf "$XDG_DATA_HOME/go"
}

info() {
  if [ -d $GOROOT ]; then
    go version
  else
    echo "Go is not installed"
  fi
}

doctor() {
  if [ -d $GOROOT ]; then
    info
    go env
  else
    echo "Go is not installed"
  fi
}
