#!/bin/bash

# VaultNote Keystore Creation Script
# Creates a release signing key for the app

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KEYSTORE_DIR="$PROJECT_DIR/android/keystore"
KEYSTORE_FILE="$KEYSTORE_DIR/vaultnote-release-key.keystore"
KEY_ALIAS="vaultnote"
KEY_VALIDITY=10000  # days (~27 years)

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

print_header "VaultNote Keystore Creation"
echo ""

# Check if keystore already exists
if [[ -f "$KEYSTORE_FILE" ]]; then
    print_error "Keystore already exists: $KEYSTORE_FILE"
    print_info "To create a new keystore, first delete the existing one:"
    echo "  rm -rf $KEYSTORE_DIR"
    exit 1
fi

# Create keystore directory
mkdir -p "$KEYSTORE_DIR"
print_success "Created keystore directory: $KEYSTORE_DIR"

# Check for JAVA_HOME
if [[ -z "$JAVA_HOME" ]]; then
    print_info "JAVA_HOME not set, attempting to find Java..."
    
    if command -v java &> /dev/null; then
        JAVA_PATH=$(readlink -f $(which java))
        JAVA_HOME=$(dirname $(dirname "$JAVA_PATH"))
        export JAVA_HOME
        print_success "Found Java at: $JAVA_HOME"
    else
        print_error "Java not found. Please install JDK and set JAVA_HOME"
        exit 1
    fi
fi

print_info "Using Java: $JAVA_HOME"
echo ""

# Prompt for keystore password
echo "Enter keystore password (minimum 6 characters):"
read -s -p "Password: " KEYSTORE_PASSWORD
echo ""

if [[ ${#KEYSTORE_PASSWORD} -lt 6 ]]; then
    print_error "Password must be at least 6 characters"
    exit 1
fi

read -s -p "Confirm Password: " KEYSTORE_PASSWORD_CONFIRM
echo ""

if [[ "$KEYSTORE_PASSWORD" != "$KEYSTORE_PASSWORD_CONFIRM" ]]; then
    print_error "Passwords do not match"
    exit 1
fi

echo ""

# Prompt for distinguished name fields
print_info "Enter certificate distinguished name information:"
echo "(Press Enter to use default values)"
echo ""

read -p "First and Last Name (CN) [VaultNote Team]: " CN
CN=${CN:-"VaultNote Team"}

read -p "Organizational Unit (OU) [Development]: " OU
OU=${OU:-"Development"}

read -p "Organization (O) [VaultNote]: " O
O=${O:-"VaultNote"}

read -p "City (L) [Manila]: " L
L=${L:-"Manila"}

read -p "State/Province (ST) [NCR]: " ST
ST=${ST:-"NCR"}

read -p "Country Code (C) [PH]: " C
C=${C:-"PH"}

echo ""
print_info "Creating keystore..."
echo ""

# Generate keystore
keytool -genkey -v \
    -keystore "$KEYSTORE_FILE" \
    -alias "$KEY_ALIAS" \
    -keyalg RSA \
    -keysize 2048 \
    -validity $KEY_VALIDITY \
    -storepass "$KEYSTORE_PASSWORD" \
    -keypass "$KEYSTORE_PASSWORD" \
    -dname "CN=$CN, OU=$OU, O=$O, L=$L, ST=$ST, C=$C"

print_success "Keystore created successfully!"
echo ""

# Create key.properties file
KEY_PROPERTIES="$PROJECT_DIR/android/key.properties"
cat > "$KEY_PROPERTIES" << EOF
# VaultNote Release Key Configuration
# IMPORTANT: Keep this file secure and do not commit to version control

storePassword=$KEYSTORE_PASSWORD
keyPassword=$KEYSTORE_PASSWORD
keyAlias=$KEY_ALIAS
storeFile=$KEYSTORE_FILE
EOF

chmod 600 "$KEY_PROPERTIES"
print_success "Created key.properties"

# Add to .gitignore
GITIGNORE="$PROJECT_DIR/android/.gitignore"
if [[ -f "$GITIGNORE" ]]; then
    if ! grep -q "keystore" "$GITIGNORE" 2>/dev/null; then
        echo "" >> "$GITIGNORE"
        echo "# Keystore files" >> "$GITIGNORE"
        echo "keystore/" >> "$GITIGNORE"
        echo "key.properties" >> "$GITIGNORE"
        print_success "Added keystore to .gitignore"
    fi
else
    cat > "$GITIGNORE" << EOF
# Keystore files
keystore/
key.properties

# Build outputs
build/

# Generated files
.gradle/
EOF
    print_success "Created .gitignore"
fi

echo ""
print_header "Important Security Notes"
echo ""
print_info "1. ${YELLOW}BACKUP YOUR KEYSTORE${NC}"
echo "   Location: $KEYSTORE_FILE"
echo "   Store it in a secure location (password manager, encrypted backup)"
echo ""
print_info "2. ${YELLOW}NEVER LOSE YOUR KEYSTORE${NC}"
echo "   Without the keystore, you cannot update your app on the Play Store"
echo "   Each app update MUST be signed with the same key"
echo ""
print_info "3. ${YELLOW}KEEP PASSWORDS SECURE${NC}"
echo "   Store passwords in a password manager"
echo "   Never commit key.properties to version control"
echo ""
print_info "4. ${YELLOW}RECOMMENDED BACKUP${NC}"
echo "   Create multiple backups in different secure locations"
echo "   Consider using Google Play App Signing for additional security"
echo ""

# Verify keystore
print_header "Verifying Keystore"
echo ""
keytool -list -v \
    -keystore "$KEYSTORE_FILE" \
    -alias "$KEY_ALIAS" \
    -storepass "$KEYSTORE_PASSWORD" | head -20

echo ""
print_success "Keystore verification complete!"
echo ""
print_info "You can now build signed APKs with: ./scripts/build.sh -k"
echo ""
