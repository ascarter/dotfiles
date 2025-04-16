#!/bin/sh

set -eu

GOROOT="$XDG_DATA_HOME/go"

# Go programming language
#
#
# rm -rf /usr/local/go && tar -C /usr/local -xzf go1.24.2.linux-amd64.tar.gz
#

# XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
# GO_DIR=${XDG_DATA_HOME}/go

# GO_VERSION=1.24.2
# GO_OS=darwin
# GO_ARCH=arm64
# GO_URL=https://go.dev/dl/go${GO_VERSION}.${GO_OS}-${GO_ARCH}.tar.gz

# rm -rf ${GO_DIR}
# curl -fsSL ${GO_URL} | tar -C ${XDG_DATA_HOME} -xz

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

  read filename checksum version <<EOF
    $(curl -s "$GO_RELEASES_URL" | jq -r --arg os "$os" --arg arch "$arch" --arg ext "$ext" '.[0].files[] | select(.os==$os and .arch==$arch and (.filename | endswith($ext))) | "\(.filename) \(.sha256) \(.version)"')
EOF

  # Check if existing Go install matches current stable
  if [ -d $GOROOT ]; then
    if [ "$($GOROOT/bin/go version)" = "go version $version $os/$arch" ]; then
      echo "Go installed is latest version $version"
      exit 0
    fi
  fi

  # Download to a temporary file
  download_url="https://go.dev/dl/$filename"
  echo "Downloading $download_url"
  temp_file=$(mktemp)
  curl -L -o "$temp_file" "$download_url"

  # Verify checksum
  if ! echo "$checksum  $temp_file" | sha256sum -c -; then
    echo "Checksum verification failed." >&2
    rm -f "$temp_file"
    exit 1
  fi
  echo "Checksum verified successfully."

  # Uninstall existing Go install
  uninstall

  # Extract the archive
  echo "Extract Go archive"
  # The tarball typically contains a top-level "go" directory.
  tar -C "$XDG_DATA_HOME" -xzf "$temp_file"
  rm -f "$temp_file"

  # Symlink binaries
  for gobin in ${GOROOT}/bin/*; do
    bin="$LOCAL_BIN_HOME/${gobin##*/}"
    if ! [ -e $bin ]; then
      echo "link $gobin -> $bin"
      ln -s $gobin $bin
    fi
  done

  echo "Go installed to $XDG_DATA_HOME/go"
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
  # Remove any existing Go installation
  echo "Removing existing Go installation at $XDG_DATA_HOME/go"
  rm -rf "$XDG_DATA_HOME/go"
}
