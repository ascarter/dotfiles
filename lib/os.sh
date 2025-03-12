export PATH=$HOME/.local/bin:$PATH

# Emulate os-release
# Deterine OS and version
case $(uname -s) in
Darwin)
  # Emulate /etc/os-release for macOS
  NAME="macOS"
  VERSION=$(sw_vers -productVersion)
  VERSION_ID="$VERSION"
  ID="macos"
  ID_LIKE="darwin"
  BUILD_ID=$(sw_vers -buildVersion)
  PRETTY_NAME="macOS $VERSION ($BUILD_ID)"
  ARCH=$(uname -m)
  OS=$(uname -s)
  ;;
Linux)
  if [[ -f /etc/os-release ]]; then
    # Source os-release file to get distribution information
    . /etc/os-release
  else
    echo "Error: /etc/os-release not found"
    exit 1
  fi
  ;;
esac

# OS helper functions
source ${DOTFILES_LIB_DIR}/os/${ID}.sh
