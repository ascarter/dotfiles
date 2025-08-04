#!/bin/sh

# SSH configuration script

set -eu

# Set default values for environment variables if not already set
: "${XDG_CONFIG_HOME:=${HOME}/.config}"
: "${DOTFILES:=${XDG_DATA_HOME:-${HOME}/.local/share}/dotfiles}"

SSH_CONFIG="${HOME}/.ssh/config"
SSH_DIR="${HOME}/.ssh"
DOTFILES_SSH_CONFIG="${XDG_CONFIG_HOME}/ssh/config"

# Check if a line exists in SSH config
ssh_config_has_line() {
  local config_file="$1"
  local pattern="$2"
  [ -f "$config_file" ] && grep -q "$pattern" "$config_file"
}

# Add a line to config if it doesn't exist
add_to_ssh_config() {
  local config_file="$1"
  local line="$2"
  local pattern="$3"

  if ! ssh_config_has_line "$config_file" "$pattern"; then
    echo "Added: $line"
    printf "%s\n" "$line" >>"$config_file"
  fi
}

# Install security key helper
case $(uname -s) in
Darwin)
  if command -v brew >/dev/null 2>&1 && [ -n "$HOMEBREW_PREFIX" ]; then
    brew install --formula "${DOTFILES}/formula/sk-libfido2.rb"
  else
    echo "Homebrew is not installed. Please install Homebrew first."
    exit 1
  fi
  ;;
esac

# Create SSH config if it doesn't exist
if [ ! -f "${SSH_CONFIG}" ]; then
  mkdir -p "${SSH_DIR}"
  touch "${SSH_CONFIG}"
fi

# Add Include directive for dotfiles SSH config
if [ -f "$DOTFILES_SSH_CONFIG" ]; then
  INCLUDE_LINE="Include ${DOTFILES_SSH_CONFIG}"

  # Check if Include is already at the top of the file
  if ! head -n 5 "$SSH_CONFIG" | grep -q "Include.*${DOTFILES_SSH_CONFIG}"; then
    # Create a temporary file with the Include at the top
    TEMP_CONFIG=$(mktemp)
    echo "$INCLUDE_LINE" >"$TEMP_CONFIG"
    echo "" >>"$TEMP_CONFIG"
    cat "$SSH_CONFIG" >>"$TEMP_CONFIG"
    mv "$TEMP_CONFIG" "$SSH_CONFIG"
    echo "Added: Include dotfiles ssh config"
  fi
else
  echo "Warning: Dotfiles SSH config not found at $DOTFILES_SSH_CONFIG"
fi

# Add security key provider
case $(uname -s) in
Darwin)
  if [ -f "${HOMEBREW_PREFIX}/lib/sk-libfido2.dylib" ]; then
    SECURITY_KEY_LINE="SecurityKeyProvider ${HOMEBREW_PREFIX}/lib/sk-libfido2.dylib"
    add_to_ssh_config "$SSH_CONFIG" "$SECURITY_KEY_LINE" "SecurityKeyProvider.*sk-libfido2"
  fi
  ;;
Linux)
  # Check for libfido2 library in common locations
  for lib_path in "/usr/lib/x86_64-linux-gnu/sk-libfido2.so" "/usr/lib/sk-libfido2.so" "/usr/local/lib/sk-libfido2.so"; do
    if [ -f "$lib_path" ]; then
      SECURITY_KEY_LINE="SecurityKeyProvider $lib_path"
      add_to_ssh_config "$SSH_CONFIG" "$SECURITY_KEY_LINE" "SecurityKeyProvider.*sk-libfido2"
      break
    fi
  done
  ;;
esac

# Set permissions on SSH config
chmod 700 "${SSH_DIR}"
chmod 600 "${SSH_CONFIG}"

echo "SSH configuration complete!"
echo ""
echo "SSH config location: $SSH_CONFIG"
echo "dotfiles SSH config: $DOTFILES_SSH_CONFIG"

# Display helpful information
case $(uname -s) in
Darwin)
  if [ -n "$HOMEBREW_PREFIX" ] && [ -f "${HOMEBREW_PREFIX}/lib/sk-libfido2.dylib" ]; then
    echo ""
    echo "Security key support is now configured!"
    echo "To generate a resident key:"
    echo "  ssh-keygen -t ed25519-sk -O resident -O verify-required -f ~/.ssh/id_ed25519_sk"
    echo "To load resident keys from your security key:"
    echo "  ssh-add -K"
  fi
  ;;
esac
