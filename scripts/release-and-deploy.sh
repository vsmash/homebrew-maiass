#!/bin/bash
# Automated release script for MAIASS Bash via Cloudflare R2
# This script creates a release, deploys to R2, and updates the Homebrew formula

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

echo "🚀 MAIASS Bash Release & Deploy"
echo "==============================="

# Configuration
BASHMAIASS_DIR="../bashmaiass"
FORMULA_FILE="Formula/maiass.rb"
R2_BASE_URL="https://releases.maiass.net"

# Get current version from maiass.sh
if [[ -f "$BASHMAIASS_DIR/maiass.sh" ]]; then
    CURRENT_VERSION=$(grep -m1 '^# MAIASS' "$BASHMAIASS_DIR/maiass.sh" | sed -E 's/.* v([0-9]+\.[0-9]+\.[0-9]+).*/\1/')
    if [[ -z "$CURRENT_VERSION" || "$CURRENT_VERSION" == "0.0.0" ]]; then
        print_error "Could not extract version from maiass.sh"
        exit 1
    fi
else
    print_error "maiass.sh not found in $BASHMAIASS_DIR"
    exit 1
fi

print_status "Current version: $CURRENT_VERSION"

# Ask for new version
echo
printf "Enter new version (current: %s): " "$CURRENT_VERSION"
read NEW_VERSION

if [[ -z "$NEW_VERSION" ]]; then
    print_warning "No version entered, using current version: $CURRENT_VERSION"
    NEW_VERSION="$CURRENT_VERSION"
fi

# Validate version format
if ! [[ "$NEW_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    print_error "Invalid version format. Use semantic versioning (e.g., 5.7.1)"
    exit 1
fi

print_status "Using version: $NEW_VERSION"

# Update version in maiass.sh if different
if [[ "$NEW_VERSION" != "$CURRENT_VERSION" ]]; then
    print_status "Updating version in maiass.sh..."
    sed -i.bak "s/^# MAIASS.* v[0-9]\+\.[0-9]\+\.[0-9]\+/# MAIASS (Modular AI-Augmented Semantic Scribe) v$NEW_VERSION/" "$BASHMAIASS_DIR/maiass.sh"
    rm -f "$BASHMAIASS_DIR/maiass.sh.bak"
    print_success "Version updated in maiass.sh"
fi

# Deploy to R2
print_status "Deploying to Cloudflare R2..."
if ! ./scripts/deploy-to-r2.sh; then
    print_error "R2 deployment failed"
    exit 1
fi

# Extract SHA256 from the deployment output (we'll need to get this from the deployment)
ARCHIVE_NAME="bashmaiass-${NEW_VERSION}.tar.gz"
R2_URL="$R2_BASE_URL/bash/$NEW_VERSION/$ARCHIVE_NAME"

# Calculate SHA256 by re-creating the archive temporarily (since deploy script cleans up)
print_status "Calculating SHA256 for formula update..."

# Create temporary release directory again
RELEASE_DIR="release-temp"
rm -rf "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR"

# Copy bashmaiass files
cp -r "$BASHMAIASS_DIR"/* "$RELEASE_DIR/"

# Remove development files
rm -rf "$RELEASE_DIR"/.git*
rm -rf "$RELEASE_DIR"/node_modules
rm -f "$RELEASE_DIR"/.env*
rm -f "$RELEASE_DIR"/maiass.log
rm -f "$RELEASE_DIR"/devlog.csv
rm -rf "$RELEASE_DIR"/scripts

# Create tarball
cd "$RELEASE_DIR" || exit 1
tar -czf "../$ARCHIVE_NAME" .
cd ..

# Calculate SHA256
if command -v shasum &> /dev/null; then
    SHA256=$(shasum -a 256 "$ARCHIVE_NAME" | cut -d' ' -f1)
elif command -v sha256sum &> /dev/null; then
    SHA256=$(sha256sum "$ARCHIVE_NAME" | cut -d' ' -f1)
else
    print_error "Neither shasum nor sha256sum found"
    exit 1
fi

# Cleanup
rm -rf "$RELEASE_DIR"
rm -f "$ARCHIVE_NAME"

print_success "SHA256: $SHA256"

# Update Homebrew formula
print_status "Updating Homebrew formula..."

if [[ ! -f "$FORMULA_FILE" ]]; then
    print_error "Formula file not found: $FORMULA_FILE"
    exit 1
fi

# Create backup
cp "$FORMULA_FILE" "$FORMULA_FILE.bak"

# Update the formula with new URL, SHA256, and version
sed -i.tmp \
    -e "s|url \".*\"|url \"$R2_URL\"|" \
    -e "s|sha256 \".*\"|sha256 \"$SHA256\"|" \
    -e "s|version \".*\"|version \"$NEW_VERSION\"|" \
    "$FORMULA_FILE"

rm -f "$FORMULA_FILE.tmp"

print_success "Formula updated with:"
print_status "  URL: $R2_URL"
print_status "  SHA256: $SHA256"
print_status "  Version: $NEW_VERSION"

# Show diff
echo
print_status "Formula changes:"
if command -v diff &> /dev/null; then
    diff -u "$FORMULA_FILE.bak" "$FORMULA_FILE" || true
fi

# Test the formula
print_status "Testing formula syntax..."
if command -v brew &> /dev/null; then
    if brew formula "$FORMULA_FILE" &> /dev/null; then
        print_success "Formula syntax is valid"
    else
        print_warning "Formula syntax check failed (but continuing)"
    fi
else
    print_warning "Homebrew not found, skipping syntax check"
fi

# Cleanup backup
rm -f "$FORMULA_FILE.bak"

echo
print_success "🎉 Release v$NEW_VERSION completed!"
echo
print_status "Next steps:"
echo "1. Review the updated formula: $FORMULA_FILE"
echo "2. Test locally: brew install --build-from-source $FORMULA_FILE"
echo "3. Commit and push changes to update the tap"
echo "4. Users can install with: brew tap vsmash/maiass && brew install maiass"
echo
print_status "R2 URL: $R2_URL"
print_status "SHA256: $SHA256"
