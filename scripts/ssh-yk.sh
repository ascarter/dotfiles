#!/bin/sh

# SSH FIDO2 Resident Key Management Script for YubiKey

set -eu

SSH_DIR="${HOME}/.ssh"

# Check if YubiKey is present
check_yubikey() {
  echo "Checking for YubiKey..."

  if ! command -v ykman >/dev/null 2>&1; then
    echo "Error: ykman not found. Please install yubikey-manager."
    echo "Install with: brew install ykman"
    exit 1
  fi

  if ! ykman list >/dev/null 2>&1; then
    echo "Error: No YubiKey detected. Please insert your YubiKey."
    exit 1
  fi

  echo "YubiKey detected"
}

# Get YubiKey serial number
get_yubikey_serial() {
  serial=$(ykman info | grep "Serial number:" | awk '{print $3}')
  if [ -z "$serial" ]; then
    echo "Error: Could not retrieve YubiKey serial number"
    exit 1
  fi
  echo "$serial"
}

# Check for existing resident keys
has_resident_keys() {
  echo "Checking for existing resident keys..."

  # Use ykman to list FIDO credentials and check for SSH keys
  if ykman fido credentials list | grep -q "ssh:"; then
    return 0
  fi
  return 1
}

# Check if key stub files exist for this YubiKey
has_key_stubs() {
  serial="$1"
  key_pattern="${SSH_DIR}/id_ed25519_sk_${serial}"

  if [ -f "$key_pattern" ] || [ -f "${key_pattern}.pub" ]; then
    return 0
  fi
  return 1
}

# Download existing resident keys
download_resident_keys() {
  serial="$1"
  echo "Downloading resident keys from YubiKey..."

  # Create temporary directory for download
  temp_dir=$(mktemp -d)
  cd "$temp_dir" || exit 1

  if ssh-keygen -K -N ""; then
    echo "Resident keys downloaded successfully"

    # Rename and move downloaded files to ~/.ssh with serial number
    for file in id_*_sk_rk*; do
      if [ -f "$file" ]; then
        case "$file" in
        *.pub)
          new_name="id_ed25519_sk_${serial}.pub"
          ;;
        *)
          new_name="id_ed25519_sk_${serial}"
          ;;
        esac
        mv "$file" "${SSH_DIR}/${new_name}"
        echo "Downloaded: $file -> ${SSH_DIR}/${new_name}"
      fi
    done

    # Clean up temp directory
    cd "$SSH_DIR"
    rm -rf "$temp_dir"

    # Show downloaded key files
    for file in "${SSH_DIR}"/id_ed25519_sk_"${serial}"*; do
      if [ -f "$file" ]; then
        echo "Key stub files exist $file"
      fi
    done
  else
    echo "Error: Failed to download resident keys"
    cd "$SSH_DIR"
    rm -rf "$temp_dir"
    return 1
  fi
}

# Add IdentityFile to SSH config
add_identity_to_ssh_config() {
  serial="$1"
  private_key="${SSH_DIR}/id_ed25519_sk_${serial}"
  ssh_config="${SSH_DIR}/config"

  echo "Adding IdentityFile to SSH config..."

  # Create SSH config if it doesn't exist
  if [ ! -f "$ssh_config" ]; then
    touch "$ssh_config"
    chmod 600 "$ssh_config"
  fi

  # Extract all existing IdentityFile entries (excluding the one we're adding)
  existing_identities=$(grep "^IdentityFile" "$ssh_config" 2>/dev/null | grep -v "id_ed25519_sk_${serial}" 2>/dev/null || true)

  # Count existing identities and calculate final count
  if [ -n "$existing_identities" ]; then
    existing_count=$(echo "$existing_identities" | wc -l)
  else
    existing_count=0
  fi
  final_count=$((existing_count + 1))

  # Check if this identity file is already in the config
  if grep -q "IdentityFile.*id_ed25519_sk_${serial}" "$ssh_config"; then
    echo "IdentityFile for serial $serial already exists in SSH config"
    identity_exists=true
  else
    identity_exists=false
  fi

  # If there will be multiple identities, ask about primary
  make_primary=false
  if [ "$final_count" -gt 1 ]; then
    if confirm "Set this YubiKey as primary SSH identity? (avoids multiple PIN prompts)"; then
      make_primary=true
    elif [ "$identity_exists" = "true" ]; then
      # Identity exists but user doesn't want to make it primary, so we're done
      return 0
    fi
  elif [ "$identity_exists" = "true" ]; then
    # Identity exists and only one identity total, so we're done
    return 0
  fi

  # For new identities or reordering existing ones, proceed with file manipulation
  # Remove all IdentityFile lines from config and save the rest
  config_without_identities=$(mktemp)
  # Remove IdentityFile lines, then clean up extra blank lines
  grep -v "^[[:space:]]*IdentityFile" "$ssh_config" | sed '/^[[:space:]]*$/N; /\n[[:space:]]*$/d' >"$config_without_identities"

  # Find insertion point (after Include statements but before Host/Match blocks)
  # Look for first Host, Match, or any other block-starting directive
  first_block_line=$(grep -n "^Host\|^Match\|^CanonicalizeHostname\|^ProxyCommand" "$config_without_identities" | head -1 | cut -d: -f1)

  if [ -n "$first_block_line" ]; then
    # Insert IdentityFile block before the first block
    head -n $((first_block_line - 1)) "$config_without_identities" >"$ssh_config"

    # Add IdentityFile entries with spacing
    echo "" >>"$ssh_config"
    if [ "$make_primary" = "true" ]; then
      echo "IdentityFile ${private_key}" >>"$ssh_config"
      [ -n "$existing_identities" ] && echo "$existing_identities" >>"$ssh_config"
    else
      [ -n "$existing_identities" ] && echo "$existing_identities" >>"$ssh_config"
      echo "IdentityFile ${private_key}" >>"$ssh_config"
    fi
    echo "" >>"$ssh_config"

    # Add the rest of the config
    tail -n +$first_block_line "$config_without_identities" >>"$ssh_config"
  else
    # No blocks found, add IdentityFile entries at the end
    cp "$config_without_identities" "$ssh_config"

    # Add IdentityFile entries with spacing
    echo "" >>"$ssh_config"
    if [ "$make_primary" = "true" ]; then
      echo "IdentityFile ${private_key}" >>"$ssh_config"
      [ -n "$existing_identities" ] && echo "$existing_identities" >>"$ssh_config"
    else
      [ -n "$existing_identities" ] && echo "$existing_identities" >>"$ssh_config"
      echo "IdentityFile ${private_key}" >>"$ssh_config"
    fi
    echo "" >>"$ssh_config"
  fi

  # Clean up temp file
  rm "$config_without_identities"

  if [ "$make_primary" = "true" ]; then
    echo "Added IdentityFile ${private_key} to SSH config (as primary key)"
  else
    echo "Added IdentityFile ${private_key} to SSH config"
  fi
}

# Generate SSH FIDO2 resident key
generate_resident_key() {
  yubikey_name="$1"
  github_user="$2"
  serial="$3"

  comment="${github_user}@users.noreply.github.com ${yubikey_name}"
  key_file="${SSH_DIR}/id_ed25519_sk_${serial}"

  echo "Generating SSH FIDO2 resident key..."
  echo "Key name: $yubikey_name"
  echo "GitHub user: $github_user"
  echo "Serial: $serial"
  echo "Comment: $comment"
  echo "Key file: $key_file"
  echo ""

  if confirm "Proceed with key generation?"; then
    echo "Generating key (touch YubiKey when prompted)..."

    if ssh-keygen -t ed25519-sk -O resident -O verify-required -C "$comment" -f "$key_file" -N ""; then
      echo "SSH FIDO2 resident key generated successfully!"
      echo "Private key: $key_file"
      echo "Public key: ${key_file}.pub"

      # Set appropriate permissions
      chmod 600 "$key_file"
      chmod 644 "${key_file}.pub"

      # Display public key
      echo ""
      echo "Your public key (copy this to GitHub/GitLab/etc.):"
      echo "----------------------------------------"
      cat "${key_file}.pub"
      echo "----------------------------------------"
    else
      echo "Error: Failed to generate SSH key"
      return 1
    fi
  else
    echo "Key generation cancelled"
    return 1
  fi
}

# Prompt for confirmation
confirm() {
  prompt="$1"

  while true; do
    printf "%s (y/n): " "$prompt"
    read -r response
    case "$response" in
    [Yy] | [Yy][Ee][Ss]) return 0 ;;
    [Nn] | [Nn][Oo]) return 1 ;;
    *) echo "Please answer yes or no." ;;
    esac
  done
}

# Get GitHub username
get_github_username() {
  if command -v gh >/dev/null 2>&1; then
    ghuser=$(gh api user --jq '.login' 2>/dev/null || true)
    if [ -n "$ghuser" ]; then
      echo "$ghuser"
      return 0
    fi
  fi

  echo "Error: gh CLI not found or not authenticated"
  echo "Please install and authenticate with: gh auth login"
  return 1
}

# Main execution
main() {
  echo "SSH FIDO2 Resident Key Manager for YubiKey"
  echo ""

  # Ensure SSH directory exists
  mkdir -p "$SSH_DIR"
  chmod 700 "$SSH_DIR"

  # Check for YubiKey
  check_yubikey

  # Get YubiKey serial number
  serial=$(get_yubikey_serial)
  echo "YubiKey serial number: $serial"
  echo ""

  # Check for existing resident keys
  if has_resident_keys; then
    echo "Resident keys found on YubiKey"

    # Check if key stub files exist
    if ! has_key_stubs "$serial"; then
      echo "Key stub files not found in ~/.ssh"
      if confirm "Download resident key files from YubiKey?"; then
        download_resident_keys "$serial"
        add_identity_to_ssh_config "$serial"
      fi
    else
      # Show existing key files
      for file in "${SSH_DIR}"/id_ed25519_sk_"${serial}"*; do
        if [ -f "$file" ]; then
          echo "Key stub files exist $file"
        fi
      done

      # Add to SSH config if keys exist
      add_identity_to_ssh_config "$serial"
    fi
  else
    echo "No resident keys found on YubiKey"
    echo ""

    if confirm "Generate a new SSH FIDO2 resident key?"; then
      # Reset terminal state and get YubiKey name
      echo "Enter a name for your YubiKey (e.g., ASC1): "
      read yubikey_name

      if [ -z "$yubikey_name" ]; then
        echo "Error: YubiKey name cannot be empty"
        exit 1
      fi

      # Get GitHub username
      if ! github_user=$(get_github_username); then
        exit 1
      fi

      echo ""
      # Generate the key
      if generate_resident_key "$yubikey_name" "$github_user" "$serial"; then
        add_identity_to_ssh_config "$serial"
      fi
    else
      echo "No action taken"
    fi
  fi

  echo ""
  echo "SSH FIDO2 key management complete!"
}

# Run main function
main "$@"
