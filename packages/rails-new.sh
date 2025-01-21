install() {
  if command -v rails-new 1>/dev/null 2>&1; then
    echo "rails-new already installed"
    exit 1
  fi

  version="0.5.0"
  platform_id=
  platform_arch=

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

  source_url="https://github.com/rails/rails-new/releases/download/v${version}/rails-new-${platform_arch}-${platform_id}.tar.gz"

  # Download and extract to ~/.local/bin
  mkdir -p ${HOME}/.local/bin
  dlog "rails-new" "installing"
  curl -L $source_url | tar -xz -C ${HOME}/.local/bin
}

uninstall() {
  if ! command -v rails-new 1>/dev/null 2>&1; then
    echo "rails-new not installed"
    exit 1
  fi

  rails_new_cmd=${HOME}/.local/bin/rails-new
  if [ -x $rails_new_cmd ]; then
    dlog "rails-new" "uninstalling"
    rm -f $rails_new_cmd
  fi
}

status() {
  if command -v rails-new 1>/dev/null 2>&1; then
    rails-new --version
  else
    echo "rails-new not installed"
    exit 1
  fi
}
