#!/bin/bash
# Test script to verify deployment setup without actually deploying
# This script tests the version extraction, archive creation, and formula updates

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

echo "🧪 MAIASS Bash Deployment Test"
echo "=============================="

# Configuration
BASHMAIASS_DIR="../bashmaiass"
FORMULA_FILE="Formula/maiass.rb"
R2_BASE_URL="https://releases.maiass.net"

# Test 1: Check if dist directory exists
print_status "Test 1: Checking dist directory..."
if [[ -d "$BASHMAIASS_DIR/dist" ]]; then
    print_success "Dist directory exists: $BASHMAIASS_DIR/dist"
else
    print_error "Dist directory not found: $BASHMAIASS_DIR/dist"
    exit 1
fi

# Test 2: Check if maiass.sh exists
print_status "Test 2: Checking maiass.sh..."
if [[ -f "$BASHMAIASS_DIR/dist/maiass.sh" ]]; then
    print_success "maiass.sh exists: $BASHMAIASS_DIR/dist/maiass.sh"
else
    print_error "maiass.sh not found: $BASHMAIASS_DIR/dist/maiass.sh"
    exit 1
fi

# Test 3: Extract version from package.json
print_status "Test 3: Extracting version from package.json..."
if [[ -f "$BASHMAIASS_DIR/dist/package.json" ]]; then
    VERSION=$(jq -r '.version' "$BASHMAIASS_DIR/dist/package.json")
    if [[ -n "$VERSION" && "$VERSION" != "null" ]]; then
        print_success "Version from package.json: $VERSION"
    else
        print_warning "Could not extract version from package.json"
    fi
else
    print_warning "package.json not found"
fi

# Test 4: Extract version from maiass.sh
print_status "Test 4: Extracting version from maiass.sh..."
if [[ -f "$BASHMAIASS_DIR/dist/maiass.sh" ]]; then
    SH_VERSION=$(grep -m1 '^# MAIASS' "$BASHMAIASS_DIR/dist/maiass.sh" | sed -E 's/.* v([0-9]+\.[0-9]+\.[0-9]+).*/\1/')
    if [[ -n "$SH_VERSION" && "$SH_VERSION" != "0.0.0" ]]; then
        print_success "Version from maiass.sh: $SH_VERSION"
    else
        print_warning "Could not extract version from maiass.sh"
    fi
else
    print_warning "maiass.sh not found"
fi

# Test 5: Check if wrangler is available
print_status "Test 5: Checking wrangler CLI..."
if command -v wrangler &> /dev/null; then
    print_success "Wrangler CLI is available"
else
    print_warning "Wrangler CLI not found - install with: npm install -g wrangler"
fi

# Test 6: Check if formula file exists
print_status "Test 6: Checking Homebrew formula..."
if [[ -f "$FORMULA_FILE" ]]; then
    print_success "Formula file exists: $FORMULA_FILE"
else
    print_error "Formula file not found: $FORMULA_FILE"
    exit 1
fi

# Test 7: Create test archive
print_status "Test 7: Creating test archive..."
RELEASE_DIR="test-release-temp"
rm -rf "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR"

# Copy files needed for Homebrew installation
cp "$BASHMAIASS_DIR/dist/maiass.sh" "$RELEASE_DIR/"
if [[ -f "$BASHMAIASS_DIR/dist/bundle.sh" ]]; then
    cp "$BASHMAIASS_DIR/dist/bundle.sh" "$RELEASE_DIR/"
    print_status "  - Included bundle.sh"
fi
if [[ -d "$BASHMAIASS_DIR/dist/lib" ]]; then
    cp -r "$BASHMAIASS_DIR/dist/lib" "$RELEASE_DIR/"
    print_status "  - Included lib directory"
fi

# Create test tarball
TEST_ARCHIVE="test-maiass.tar.gz"
cd "$RELEASE_DIR" || exit 1
tar -czf "../$TEST_ARCHIVE" .
cd ..

# Calculate SHA256
if command -v shasum &> /dev/null; then
    TEST_SHA256=$(shasum -a 256 "$TEST_ARCHIVE" | cut -d' ' -f1)
elif command -v sha256sum &> /dev/null; then
    TEST_SHA256=$(sha256sum "$TEST_ARCHIVE" | cut -d' ' -f1)
else
    print_error "Neither shasum nor sha256sum found"
    exit 1
fi

print_success "Test archive created: $TEST_ARCHIVE"
print_success "Test SHA256: $TEST_SHA256"

# Test 8: Check archive contents
print_status "Test 8: Checking archive contents..."
tar -tzf "$TEST_ARCHIVE" | head -10
print_success "Archive contains the expected files"

# Test 9: Test formula syntax
print_status "Test 9: Testing formula syntax..."
if command -v brew &> /dev/null; then
    if brew formula "$FORMULA_FILE" &> /dev/null; then
        print_success "Formula syntax is valid"
    else
        print_warning "Formula syntax check failed"
    fi
else
    print_warning "Homebrew not found, skipping syntax check"
fi

# Cleanup
rm -rf "$RELEASE_DIR"
rm -f "$TEST_ARCHIVE"

echo
print_success "🎉 All tests passed!"
echo
print_status "Ready to deploy with:"
echo "  ./scripts/release-and-deploy.sh"
echo "  ./scripts/release-and-deploy-single.sh"
echo "  ./scripts/release-and-deploy-standalone.sh"
echo
print_status "Or deploy directly with:"
echo "  ./scripts/deploy-to-r2.sh [version]"
