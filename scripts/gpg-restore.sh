#!/bin/sh
# Restore GPG key from backup to YubiKey
#
# Usage: ./gpg-restore.sh backup.tar.gz

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BACKUP_FILE="$1"

# Check if backup file is provided
if [ -z "$BACKUP_FILE" ]; then
  printf "${RED}Usage: $0 backup.tar.gz${NC}\n"
  printf "\n"
  printf "Restores GPG key from backup to YubiKey.\n"
  exit 1
fi

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

# Warning about reset
printf "${YELLOW}⚠️  WARNING: This will reset the YubiKey's OpenPGP applet!${NC}\n"
printf "   All existing OpenPGP keys on the YubiKey will be erased.\n"
printf "\n"
printf "Continue with YubiKey reset and restore? (type 'yes' to continue): "
read confirm
if [ "$confirm" != "yes" ]; then
  printf "Operation cancelled.\n"
  exit 0
fi

# Create temporary directory for extraction
TEMP_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t 'gpg-restore')

printf "\n${BLUE}Step 1: Extracting backup...${NC}\n"
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
    exit 1
  fi
done

printf "\n${BLUE}Step 2: Resetting YubiKey OpenPGP applet...${NC}\n"
ykman openpgp reset

printf "\n${BLUE}Step 3: Importing GPG keys...${NC}\n"

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

full_name=$(id -F 2>/dev/null || id -un)
login_user=$(gh api user --jq '.login' 2>/dev/null || whoami)

printf "\n${BLUE}Step 5: Instructions for YubiKey Configuration${NC}\n"
printf "You'll be prompted to configure your YubiKey with these recommended settings:\n"
printf "  - Admin PIN: 8+ digits (default: 12345678)\n"
printf "  - User PIN: 6+ digits (default: 123456)\n"
printf "  - Name: ${full_name}\n"
printf "  - Login: ${login_user}\n"
printf "  - URL: https://github.com/${login_user}.gpg\n"
printf "\n"
read dummy

# Configure YubiKey - user must do this interactively
printf "\n${BLUE}Starting YubiKey configuration...${NC}\n"
gpg --card-edit

printf "${BLUE}Step 6: Instructions for Moving Subkeys to YubiKey${NC}\n"
printf "\n${YELLOW}⚠️  IMPORTANT: This will move your private subkeys to the YubiKey.${NC}\n"
printf "   After this, the keys will only exist on the YubiKey hardware!\n"
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
printf "Press Enter to start YubiKey configuration..."
printf "\n${BLUE}Starting key transfer to YubiKey...${NC}\n"
read dummy

# Start GPG edit session for moving keys to card
gpg --expert --edit-key "$KEYID"

printf "\n${BLUE}Step 7: Verifying YubiKey setup...${NC}\n"
gpg --card-status

printf "\n${GREEN}✅ YubiKey restore process complete!${NC}\n"

# Cleanup
rm -rf "$TEMP_DIR"

printf "\n${BLUE}Next steps:${NC}\n"
printf "1. Test GPG signing: echo 'test' | gpg --clearsign\n"
printf "2. Test Git signing: git commit --allow-empty -m 'Test GPG signing'\n"
printf "\n${YELLOW}💡 Your YubiKey is now ready to use!${NC}\n"
