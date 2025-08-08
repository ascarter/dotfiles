#!/bin/sh
# gpg-restore.sh - Restore GPG key from backup to YubiKey
#
# Usage: ./gpg-restore.sh [backup_directory]
#        Default backup directory is current directory

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to prompt for yes/no confirmation
prompt() {
  printf "%s (y/N): " "$1"
  read -r choice
  case "$choice" in
  [yY] | [yY][eE][sS]) return 0 ;;
  *) return 1 ;;
  esac
}

# Show usage
show_usage() {
  printf "Usage: $0 [backup_directory]\n"
  printf "\n"
  printf "Restores GPG key from backup to YubiKey.\n"
  printf "Default backup directory is current directory.\n"
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

# Set backup directory (default to current directory)
if [ $# -eq 0 ]; then
  BACKUP_DIR="."
elif [ $# -eq 1 ]; then
  BACKUP_DIR="$1"
else
  printf "${RED}Error: Too many arguments${NC}\n"
  printf "\n"
  show_usage
  exit 1
fi

printf "${BLUE}🔑 GPG YubiKey Restore Script${NC}\n"
printf "===============================\n"
printf "\n"

# Check if backup directory exists
if [ ! -d "$BACKUP_DIR" ]; then
  printf "${RED}❌ Error: Backup directory not found: $BACKUP_DIR${NC}\n"
  exit 1
fi

printf "${GREEN}✅ Found backup directory: $BACKUP_DIR${NC}\n"

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

printf "${BLUE}Step 1: Inspecting backup...${NC}\n"
# Find master key file in backup directory
MASTER_FILE=$(find "$BACKUP_DIR" -name "*-master.asc" -type f | head -n1)

if [ -z "$MASTER_FILE" ]; then
  printf "${RED}❌ Error: Could not locate master key file in backup${NC}\n"
  exit 1
fi

# Auto-detect the KEYID from the master key filename
KEYID=$(basename "$MASTER_FILE" | sed -E 's#-master\.asc$##')

if [ -z "$KEYID" ]; then
  printf "${RED}❌ Error: Could not detect GPG key ID from backup files${NC}\n"
  exit 1
fi

printf "${BLUE}Detected Key ID: $KEYID${NC}\n"

# Locate optional README file in backup directory
README_FILE=$(find "$BACKUP_DIR" -name "README*" -type f | head -n1)

# Verify required files exist
printf "\n${BLUE}Verifying backup contents:${NC}\n"
for file in "${KEYID}-master.asc" "${KEYID}-subkeys.asc" "ownertrust.txt"; do
  if [ -f "$BACKUP_DIR/$file" ]; then
    printf "  ${GREEN}✅ $file${NC}\n"
  else
    printf "  ${RED}❌ $file (missing)${NC}\n"
    printf "${RED}❌ Error: Required backup files are missing!${NC}\n"
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
if gpg --card-status 2>/dev/null | grep -E "(Signature key|Encryption key|Authentication key)" | grep -vq "\[none\]"; then
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
  gpg --card-status | grep -E "(Signature key|Encryption key|Authentication key)" | grep -v "\[none\]" | sed 's/^/    /'
else
  printf "  ${GREEN}ℹ️  YubiKey OpenPGP applet is empty${NC}\n"
fi

# Determine operation mode
printf "\n${BLUE}Operation: Restore GPG key to YubiKey${NC}\n"
printf "This will import keys from backup and move subkeys to YubiKey.\n"

# Warning and confirmation
printf "\n"
if [ "$YUBIKEY_HAS_KEYS" = "true" ]; then
  printf "${YELLOW}⚠️  WARNING: This will reset the YubiKey's OpenPGP applet and erase existing keys!${NC}\n"
else
  printf "${BLUE}ℹ️  YubiKey appears empty. Reset is optional; you can skip to keep counters and settings, or reset to ensure a clean state.${NC}\n"
fi
if [ "$KEY_EXISTS" = "true" ]; then
  printf "   Local keys will be reimported from backup.\n"
fi

# Show backup README (if available) before proceeding
if [ -n "$README_FILE" ]; then
  printf "\n${BLUE}Backup README:${NC}\n"
  sed 's/^/    /' "$README_FILE"
fi

# Confirm operation
printf "\n"
if ! prompt "Continue with this operation?"; then
  printf "Operation cancelled.\n"
  exit 0
fi

# Reset YubiKey OpenPGP applet
if [ "$YUBIKEY_HAS_KEYS" = "true" ]; then
  printf "\n${BLUE}Step 2: Resetting YubiKey OpenPGP applet (existing keys detected)...${NC}\n"
  ykman openpgp reset
else
  printf "\n${BLUE}Step 2: YubiKey reset (optional)${NC}\n"
  if prompt "Reset the YubiKey OpenPGP applet before proceeding?"; then
    ykman openpgp reset
  else
    printf "Skipping YubiKey reset.\n"
  fi
fi

printf "\n${BLUE}Step 3: Cleaning up existing stubs for this key...${NC}\n"

# Remove only shadowed stubs corresponding to this key's keygrips (derived from backup, no import yet)
keygrips=$({
  cat "$BACKUP_DIR/${KEYID}-master.asc"
  cat "$BACKUP_DIR/${KEYID}-subkeys.asc"
} 2>/dev/null | gpg --show-keys --with-colons --with-keygrip 2>/dev/null | awk -F: '$1=="grp"{print $10}' | sort -u)
for grip in $keygrips; do
  f="$HOME/.gnupg/private-keys-v1.d/$grip.key"
  if [ -f "$f" ] && grep -q 'shadowed' "$f" 2>/dev/null; then
    rm -f "$f"
    printf "  Removed stub: %s\n" "$f"
  fi
done

printf "\n${BLUE}Step 4: Importing GPG keys from backup...${NC}\n"

# Import master key
printf "Importing master key...\n"
gpg --import "$BACKUP_DIR/${KEYID}-master.asc"

# Import subkeys
printf "Importing subkeys...\n"
gpg --import "$BACKUP_DIR/${KEYID}-subkeys.asc"

# Import trust settings
printf "Importing trust settings...\n"
gpg --import-ownertrust "$BACKUP_DIR/ownertrust.txt"

# Get user info for YubiKey configuration
uid_line=$(gpg --list-keys --with-colons "$KEYID" | awk -F: '$1=="uid"{print $10; exit}')
name=$(printf "%s" "$uid_line" | sed -E 's/ *<[^>]*>//; s/ *\([^)]*\)//; s/^ *//; s/ *$//')
login=$(printf "%s" "$uid_line" | sed -nE 's/.*<([^>]+)>.*/\1/p' | sed -E 's/@.*$//')
url="https://github.com/${login}.gpg"

printf "\n${BLUE}Step 5: YubiKey Configuration${NC}\n"

# Configure PINs via ykman
printf "${BLUE}Setting YubiKey PINs...${NC}\n"

# Change User PIN
printf "\n${BLUE}Changing User PIN (default: 123456)${NC}\n"
ykman openpgp access change-pin

# Change Admin PIN
printf "\n${BLUE}Changing Admin PIN (default: 12345678)${NC}\n"
ykman openpgp access change-admin-pin

printf "\n${GREEN}✅ PINs configured successfully${NC}\n"

# Configure metadata
printf "\n${BLUE}Setting YubiKey metadata...${NC}\n"
printf "Configure your YubiKey with these settings:\n"
printf "  - Name: ${name}\n"
printf "  - Login: ${login}\n"
printf "  - URL: ${url}\n"
printf "\n"
printf "Press Enter to start metadata configuration..."
read dummy

# Configure YubiKey - user must do this interactively
printf "\n${BLUE}Starting metadata configuration...${NC}\n"
printf "${BLUE}In the GPG card editor, run these commands:${NC}\n"
printf "  ${GREEN}admin${NC}       (enable admin commands)\n"
printf "  ${GREEN}name${NC}        (enter: %s)\n" "$name"
printf "  ${GREEN}login${NC}       (enter: %s)\n" "$login"
printf "  ${GREEN}url${NC}         (enter: %s)\n" "$url"
printf "  ${GREEN}quit${NC}        (exit the card editor)\n"
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

# Cleanup (no temporary files created during restore)

printf "\n${BLUE}Next steps:${NC}\n"
printf "1. Test GPG signing: echo 'test' | gpg --clearsign\n"
printf "2. Test Git signing: git commit --allow-empty -m 'Test GPG signing'\n"
printf "\n${YELLOW}💡 Your YubiKey is now ready to use!${NC}\n"
printf "\n${BLUE}Multi-YubiKey Usage:${NC}\n"
printf "• Run this script again with other YubiKeys to set them up identically\n"
printf "• All YubiKeys with the same subkeys work interchangeably\n"
printf "• GPG will work with whichever YubiKey is currently inserted\n"
