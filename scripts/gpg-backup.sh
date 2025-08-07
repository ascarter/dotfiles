#!/bin/sh
# gpg-backup.sh - Create comprehensive GPG key backup
#
# Usage: ./gpg-backup.sh [target_directory] [key_id]
#        Default target directory is current directory
#        If key_id not provided, will prompt to select from available keys

# Check if running in interactive mode
if [ -t 0 ] && [ -t 1 ]; then
  INTERACTIVE=true
else
  INTERACTIVE=false
fi

# Function to discover and select GPG key
discover_key() {
  printf "Scanning for GPG secret keys...\n" >&2

  # Get list of secret keys
  KEYS=$(gpg --list-secret-keys --keyid-format=long --with-colons | grep "^sec" | cut -d: -f5)

  if [ -z "$KEYS" ]; then
    printf "Error: No GPG secret keys found!\n"
    printf "Please create or import a GPG key first.\n"
    exit 1
  fi

  # Count keys
  KEY_COUNT=$(printf "%s\n" "$KEYS" | wc -l | tr -d ' ')

  if [ "$KEY_COUNT" -eq 1 ]; then
    # Only one key, use it automatically
    SELECTED_KEY="$KEYS"
    printf "Found one GPG key: $SELECTED_KEY\n" >&2
  else
    # Multiple keys, let user choose
    printf "\nFound multiple GPG keys:\n" >&2
    printf "%s\n" "$KEYS" | nl -v0 -s". " >&2
    printf "\n" >&2

    while true; do
      printf "Select key number (0-%d): " $((KEY_COUNT - 1)) >&2
      read selection

      # Validate selection
      if [ "$selection" -ge 0 ] && [ "$selection" -lt "$KEY_COUNT" ] 2>/dev/null; then
        SELECTED_KEY=$(printf "%s\n" "$KEYS" | sed -n "$((selection + 1))p")
        break
      else
        printf "Invalid selection. Please enter a number between 0 and %d.\n" $((KEY_COUNT - 1)) >&2
      fi
    done
  fi

  # Show key details
  printf "\nSelected key details:\n" >&2
  gpg --list-secret-keys --keyid-format=long "$SELECTED_KEY" >&2
  printf "\n" >&2

  if [ "$INTERACTIVE" = "true" ]; then
    printf "Use this key for backup? (y/N): " >&2
    read confirm
    case "$confirm" in
    [Yy]*)
      printf "$SELECTED_KEY"
      return 0
      ;;
    *)
      printf "Backup cancelled.\n" >&2
      exit 0
      ;;
    esac
  else
    printf "Non-interactive mode: using key automatically\n" >&2
    printf "$SELECTED_KEY"
    return 0
  fi
}

TIMESTAMP=$(date "+%Y%m%d_%H%M")

# Parse arguments
TARGET_DIR="."
KEYID=""

case $# in
0)
  # No arguments - use defaults
  ;;
1)
  # One argument - could be target_dir or key_id
  if gpg --list-secret-keys --keyid-format=long "$1" >/dev/null 2>&1; then
    # It's a valid key ID
    KEYID="$1"
  else
    # Assume it's a target directory
    TARGET_DIR="$1"
  fi
  ;;
2)
  # Two arguments - target_dir and key_id
  TARGET_DIR="$1"
  KEYID="$2"
  ;;
*)
  printf "Usage: $0 [target_directory] [key_id]\n"
  printf "\n"
  printf "Creates a timestamped GPG backup archive.\n"
  printf "If key_id not provided, will prompt to select from available keys.\n"
  printf "Default target directory is current directory.\n"
  exit 1
  ;;
esac

# Discover key if not provided
if [ -z "$KEYID" ]; then
  KEYID=$(discover_key)
fi

# Validate the key exists
if ! gpg --list-secret-keys --keyid-format=long "$KEYID" >/dev/null 2>&1; then
  printf "Error: GPG key $KEYID not found!\n"
  printf "Available keys:\n"
  gpg --list-secret-keys --keyid-format=long
  exit 1
fi

# Create backup directory name with key ID for uniqueness
SHORT_KEYID=$(printf "%s" "$KEYID" | tail -c 9)
BACKUP_DIR="gpg-backup-${SHORT_KEYID}-${TIMESTAMP}"

# Create target directory if it doesn't exist
if [ ! -d "$TARGET_DIR" ]; then
  printf "Creating target directory: $TARGET_DIR\n"
  mkdir -p "$TARGET_DIR"
fi

# Create backup directory path
BACKUP_PATH="${TARGET_DIR}/${BACKUP_DIR}"

printf "Creating GPG backup for key: ${KEYID}\n"
printf "Target directory: ${TARGET_DIR}\n"
printf "Backup directory: ${BACKUP_DIR}\n"

# Create backup directory
mkdir -p "${BACKUP_PATH}"

printf "Exporting master secret key...\n"
gpg --armor --export-secret-key ${KEYID} >"${BACKUP_PATH}/${KEYID}-master.asc"

printf "Exporting subkeys...\n"
gpg --armor --export-secret-subkeys ${KEYID} >"${BACKUP_PATH}/${KEYID}-subkeys.asc"

printf "Exporting public key...\n"
gpg --armor --export ${KEYID} >"${BACKUP_PATH}/${KEYID}-public.asc"

printf "Exporting SSH public key (from auth subkey)...\n"
gpg --export-ssh-key ${KEYID}! >"${BACKUP_PATH}/${KEYID}-ssh.pub" 2>/dev/null || printf "Note: No SSH key exported (no auth subkey or not supported)\n"

printf "Exporting trust database...\n"
gpg --export-ownertrust >"${BACKUP_PATH}/ownertrust.txt"

printf "Copying revocation certificate...\n"
if [ -f ~/.gnupg/openpgp-revocs.d/${KEYID}.rev ]; then
  cp ~/.gnupg/openpgp-revocs.d/${KEYID}.rev "${BACKUP_PATH}/"
else
  printf "Warning: No revocation certificate found\n"
fi

# Get key information for README
KEY_INFO=$(gpg --list-secret-keys --keyid-format=long "$KEYID")
CREATION_DATE=$(printf "%s" "$KEY_INFO" | grep "created:" | head -1 | sed 's/.*created: \([0-9-]*\).*/\1/' || date +%Y-%m-%d)

# Extract User IDs
USER_IDS=$(gpg --list-keys --with-colons "$KEYID" | grep "^uid" | cut -d: -f10 | sed 's/.*<\(.*\)>.*/\1/' | head -5)

# Get subkey information
SUBKEY_INFO=$(gpg --list-secret-keys --keyid-format=long "$KEYID" | grep "^ssb" | head -5)

# Create README with key information
cat >"${BACKUP_PATH}/README.txt" <<EOF
GPG Key Backup - ${TIMESTAMP}
=============================

Master Key ID: ${KEYID}
Creation Date: ${CREATION_DATE}
Backup Created: $(date)

User IDs:
$(printf "%s\n" "$USER_IDS" | sed 's/^/- /')

Key Structure:
$(printf "%s\n" "$SUBKEY_INFO" | sed 's/^/- /')

Files in this backup:
- ${KEYID}-master.asc: Master secret key
- ${KEYID}-subkeys.asc: All subkeys
- ${KEYID}-public.asc: Public key for sharing
- ${KEYID}-ssh.pub: SSH public key (if available)
- ownertrust.txt: Trust database
- ${KEYID}.rev: Revocation certificate (if exists)

Restore commands:
==============
Use gpg-restore.sh script with this backup file.

Or manually:
gpg --import ${KEYID}-master.asc
gpg --import ${KEYID}-subkeys.asc
gpg --import-ownertrust ownertrust.txt

To move subkeys to YubiKey after restore:
gpg --expert --edit-key ${KEYID}
(Select each subkey and use 'keytocard' command)

Store this backup securely offline!
EOF

# Create tarball in target directory
BACKUP_FILE="${TARGET_DIR}/${BACKUP_DIR}.tar.gz"
tar -czf "${BACKUP_FILE}" -C "${TARGET_DIR}" "${BACKUP_DIR}"
rm -rf "${BACKUP_PATH}"

printf "\n"
printf "✅ Backup created: ${BACKUP_FILE}\n"
printf "📁 Size: %s\n" "$(du -h "${BACKUP_FILE}" | cut -f1)"
printf "\n"
printf "🔐 IMPORTANT: Store this backup securely!\n"
printf "📝 Use gpg-restore.sh to restore to a YubiKey\n"
printf "\n"
printf "Example restore usage:\n"
printf "  ./gpg-restore.sh \"${BACKUP_FILE}\"\n"
