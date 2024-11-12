install() {
  local version="0.4.1"

  local platform_id=
  local platform_arch=

  case $OS in
    Darwin )
      platform_id="apple-darwin"
      ;;
    Linux )
      platform_id="unknown-linux-gnu"
      ;;
  esac

  case $ARCH in
    arm64 )
      platform_arch="aarch64"
      ;;
    x86_64 )
      platform_arch="x86_64"
      ;;
  esac

  local source_url="https://github.com/rails/rails-new/releases/download/v${version}/rails-new-${platform_arch}-${platform_id}.tar.gz"

  # Download and extract to ~/.local/bin
  curl -L $source_url | tar -xz -C ${TARGET}/.local/bin
}

install
${TARGET}/.local/bin/rails-new --version


