#!/bin/sh
# gpg-restore.sh - Restore GPG key from backup to YubiKey
#
# Usage: ./gpg-restore.sh backup.tar.gz

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to prompt for yes/no confirmation
prompt() {
  printf "%s (y/N): " "$1" >&2
  read choice
  case "$choice" in
  [yY] | [yY][eE][sS]) return 0 ;;
  *) return 1 ;;
  esac
}

# Show usage
show_usage() {
  printf "Usage: $0 backup.tar.gz\n"
  printf "\n"
  printf "Restores GPG key from backup to YubiKey.\n"
  printf "\n"
  printf "Options:\n"
  printf "  -h    Show this help message\n"
}

# Parse options with getopts
while getopts "h" opt; do
  case $opt in
  h)
    show_usage
    exit 0
    ;;
  \?)
    printf "${RED}Invalid option: -$OPTARG${NC}\n" >&2
    show_usage
    exit 1
    ;;
  esac
done

# Shift past the options
shift $((OPTIND - 1))

# Check if backup file is provided
if [ $# -ne 1 ]; then
  printf "${RED}Error: backup.tar.gz file is required${NC}\n"
  printf "\n"
  show_usage
  exit 1
fi

BACKUP_FILE="$1"

printf "${BLUE}🔑 GPG YubiKey Restore Script${NC}\n"
printf "===============================\n"
printf "\n"

# Check if backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
  printf "${RED}❌ Error: Backup file not found: $BACKUP_FILE${NC}\n"
  exit 1
fi

# Check if it's a .tar.gz file
case "$BACKUP_FILE" in
*.tar.gz) ;;
*)
  printf "${RED}❌ Error: File must be a .tar.gz archive${NC}\n"
  exit 1
  ;;
esac

printf "${GREEN}✅ Found backup file: $BACKUP_FILE${NC}\n"

# Check if YubiKey is detected
if ! command -v ykman >/dev/null 2>&1; then
  printf "${RED}❌ Error: ykman not found! Please install YubiKey Manager.${NC}\n"
  exit 1
fi

if ! ykman list | grep -q "YubiKey"; then
  printf "${RED}❌ Error: No YubiKey detected!${NC}\n"
  printf "Please insert your YubiKey and try again.\n"
  exit 1
fi

printf "${GREEN}✅ YubiKey detected${NC}\n"

# Show YubiKey info
printf "\n${BLUE}YubiKey Information:${NC}\n"
ykman info
printf "\n"

# Create temporary directory for extraction
TEMP_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t 'gpg-restore')

printf "${BLUE}Step 1: Extracting backup...${NC}\n"
tar -xzf "$BACKUP_FILE" -C "$TEMP_DIR"

# Find the extracted directory
EXTRACT_DIR=""
for dir in "$TEMP_DIR"/*/; do
  if [ -d "$dir" ]; then
    EXTRACT_DIR="${dir%/}"
    break
  fi
done

if [ -z "$EXTRACT_DIR" ]; then
  printf "${RED}❌ Error: Could not find extracted directory${NC}\n"
  rm -rf "$TEMP_DIR"
  exit 1
fi

# Auto-detect the KEYID from the filenames
KEYID=""
for file in "$EXTRACT_DIR"/*-master.asc; do
  if [ -f "$file" ]; then
    KEYID=$(basename "$file" | sed 's/-master\.asc$//')
    break
  fi
done

if [ -z "$KEYID" ]; then
  printf "${RED}❌ Error: Could not detect GPG key ID from backup files${NC}\n"
  rm -rf "$TEMP_DIR"
  exit 1
fi

printf "${BLUE}Detected Key ID: $KEYID${NC}\n"

# Verify required files exist
printf "\n${BLUE}Verifying backup contents:${NC}\n"
for file in "${KEYID}-master.asc" "${KEYID}-subkeys.asc" "ownertrust.txt"; do
  if [ -f "$EXTRACT_DIR/$file" ]; then
    printf "  ${GREEN}✅ $file${NC}\n"
  else
    printf "  ${RED}❌ $file (missing)${NC}\n"
    printf "${RED}❌ Error: Required backup files are missing!${NC}\n"
    rm -rf "$TEMP_DIR"
    exit 1
  fi
done

# Check if key already exists locally
KEY_EXISTS=false
if gpg --list-secret-keys "$KEYID" >/dev/null 2>&1; then
  KEY_EXISTS=true
fi

# Check current YubiKey status
YUBIKEY_HAS_KEYS=false
if gpg --card-status 2>/dev/null | grep -q "Signature key"; then
  YUBIKEY_HAS_KEYS=true
fi

# Display current state and options
printf "\n${BLUE}Current State Analysis:${NC}\n"
if [ "$KEY_EXISTS" = "true" ]; then
  printf "  ${GREEN}✅ GPG key $KEYID already exists locally${NC}\n"
else
  printf "  ${YELLOW}ℹ️  GPG key $KEYID not found locally${NC}\n"
fi

if [ "$YUBIKEY_HAS_KEYS" = "true" ]; then
  printf "  ${YELLOW}⚠️  YubiKey already contains OpenPGP keys${NC}\n"
  gpg --card-status | grep -E "(Signature key|Encryption key|Authentication key)" | sed 's/^/    /'
else
  printf "  ${GREEN}ℹ️  YubiKey OpenPGP applet is empty${NC}\n"
fi

# Determine operation mode
printf "\n${BLUE}Operation: Restore GPG key to YubiKey${NC}\n"
printf "This will import keys from backup and move subkeys to YubiKey.\n"

# Warning and confirmation
printf "\n"
printf "${YELLOW}⚠️  WARNING: This will reset the YubiKey's OpenPGP applet!${NC}\n"
if [ "$YUBIKEY_HAS_KEYS" = "true" ]; then
  printf "   Existing YubiKey keys will be erased.\n"
fi
if [ "$KEY_EXISTS" = "true" ]; then
  printf "   Local keys will be reimported from backup.\n"
fi

printf "\n"
if ! prompt "Continue with this operation?"; then
  printf "Operation cancelled.\n"
  rm -rf "$TEMP_DIR"
  exit 0
fi

# Reset YubiKey OpenPGP applet
printf "\n${BLUE}Step 2: Resetting YubiKey OpenPGP applet...${NC}\n"
ykman openpgp reset

# Import keys - always import from backup to ensure we have the private key material
printf "\n${BLUE}Step 3: Importing GPG keys from backup...${NC}\n"

# Import master key
printf "Importing master key...\n"
gpg --import "$EXTRACT_DIR/${KEYID}-master.asc"

# Import subkeys
printf "Importing subkeys...\n"
gpg --import "$EXTRACT_DIR/${KEYID}-subkeys.asc"

# Import trust settings
printf "Importing trust settings...\n"
gpg --import-ownertrust "$EXTRACT_DIR/ownertrust.txt"

printf "\n${BLUE}Step 4: Cleaning up old YubiKey stubs...${NC}\n"
# Remove any existing YubiKey key stubs that might conflict
find ~/.gnupg/private-keys-v1.d/ -name "*.key" -delete 2>/dev/null || true

# Re-import subkeys to ensure we have local copies for moving to card
printf "Ensuring local subkey copies are available for transfer...\n"
gpg --import "$EXTRACT_DIR/${KEYID}-subkeys.asc"

# Get user info for YubiKey configuration
full_name=$(gpg --list-keys --with-colons "$KEYID" | grep "^uid" | head -1 | cut -d: -f10 | sed 's/ <.*//' | sed 's/.*(//' | sed 's/).*//')
if [ -z "$full_name" ]; then
  full_name=$(id -F 2>/dev/null || id -un)
fi

login_user=$(gh api user --jq '.login' 2>/dev/null || whoami)

printf "\n${BLUE}Step 5: YubiKey Configuration${NC}\n"
printf "Configure your YubiKey with these recommended settings:\n"
printf "  - Admin PIN: 8+ digits (default: 12345678)\n"
printf "  - User PIN: 6+ digits (default: 123456)\n"
printf "  - Name: ${full_name}\n"
printf "  - Login: ${login_user}\n"
printf "  - URL: https://github.com/${login_user}.gpg\n"
printf "\n"
printf "Press Enter to start YubiKey configuration..."
read dummy

# Configure YubiKey - user must do this interactively
printf "\n${BLUE}Starting YubiKey configuration...${NC}\n"
gpg --card-edit

printf "\n${BLUE}Step 6: Moving Subkeys to YubiKey${NC}\n"
printf "\n${YELLOW}⚠️  IMPORTANT: This will move your private subkeys to the YubiKey.${NC}\n"
printf "   After this, the subkeys will only exist on the YubiKey hardware!\n"
printf "\n"
printf "In the GPG key editing prompt, run these commands:\n"
printf "  ${GREEN}key 2${NC} (select signing subkey)\n"
printf "  ${GREEN}keytocard${NC} -> select ${GREEN}1${NC} (Signature key)\n"
printf "  ${GREEN}key 2${NC} (deselect)\n"
printf "  ${GREEN}key 3${NC} (select encryption subkey)\n"
printf "  ${GREEN}keytocard${NC} -> select ${GREEN}2${NC} (Encryption key)\n"
printf "  ${GREEN}key 3${NC} (deselect)\n"
printf "  ${GREEN}key 4${NC} (select authentication subkey)\n"
printf "  ${GREEN}keytocard${NC} -> select ${GREEN}3${NC} (Authentication key)\n"
printf "  ${GREEN}save${NC}\n"
printf "\n"
printf "Press Enter to start the key transfer process..."
read dummy

# Start GPG edit session for moving keys to card
printf "\n${BLUE}Starting key transfer to YubiKey...${NC}\n"
gpg --expert --edit-key "$KEYID"

printf "\n${BLUE}Step 7: Verifying YubiKey setup...${NC}\n"
printf "YubiKey card status:\n"
gpg --card-status

printf "\nSecret keys status:\n"
gpg --list-secret-keys --keyid-format=long "$KEYID"

printf "\n${GREEN}✅ YubiKey restore process complete!${NC}\n"

# Cleanup
rm -rf "$TEMP_DIR"

printf "\n${BLUE}Next steps:${NC}\n"
printf "1. Test GPG signing: echo 'test' | gpg --clearsign\n"
printf "2. Test Git signing: git commit --allow-empty -m 'Test GPG signing'\n"
printf "\n${YELLOW}💡 Your YubiKey is now ready to use!${NC}\n"
printf "\n${BLUE}Multi-YubiKey Usage:${NC}\n"
printf "• Run this script again with other YubiKeys to set them up identically\n"
printf "• All YubiKeys with the same subkeys work interchangeably\n"
printf "• GPG will work with whichever YubiKey is currently inserted\n"
