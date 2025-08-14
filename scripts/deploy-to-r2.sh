#!/bin/bash
# Deploy MAIASS bash release to Cloudflare R2
# This allows Homebrew formula to work even if GitHub repo becomes private

# Note: Don't use set -e here so we can continue uploading other files if one fails

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

echo "☁️  MAIASS Bash R2 Deployment"
echo "============================"

# Configuration
BASHMAIASS_DIR="../bashmaiass"
R2_BASE_URL="https://releases.maiass.net"
R2_BUCKET="maiass-releases"

# Get version from maiass.sh script
if [[ -f "$BASHMAIASS_DIR/maiass.sh" ]]; then
    VERSION=$(grep -m1 '^# MAIASS' "$BASHMAIASS_DIR/maiass.sh" | sed -E 's/.* v([0-9]+\.[0-9]+\.[0-9]+).*/\1/')
    if [[ -z "$VERSION" || "$VERSION" == "0.0.0" ]]; then
        print_error "Could not extract version from maiass.sh"
        exit 1
    fi
else
    print_error "maiass.sh not found in $BASHMAIASS_DIR"
    exit 1
fi

print_status "Deploying MAIASS Bash v$VERSION to R2..."

# Check if wrangler is available
if ! command -v wrangler &> /dev/null; then
    print_error "Wrangler CLI not found"
    print_status "Install with: npm install -g wrangler"
    exit 1
fi

# Create temporary release directory
RELEASE_DIR="release-temp"
rm -rf "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR"

print_status "Creating release archive..."

# Copy bashmaiass files to release directory
cp -r "$BASHMAIASS_DIR"/* "$RELEASE_DIR/"

# Remove development files that shouldn't be in release
rm -rf "$RELEASE_DIR"/.git*
rm -rf "$RELEASE_DIR"/node_modules
rm -f "$RELEASE_DIR"/.env*
rm -f "$RELEASE_DIR"/maiass.log
rm -f "$RELEASE_DIR"/devlog.csv

# Create tarball
ARCHIVE_NAME="bashmaiass-${VERSION}.tar.gz"
print_status "Creating archive: $ARCHIVE_NAME"

cd "$RELEASE_DIR" || {
    print_error "Failed to enter release directory"
    exit 1
}

# Create the tarball with proper structure
tar -czf "../$ARCHIVE_NAME" .
cd ..

# Calculate SHA256
print_status "Calculating SHA256..."
if command -v shasum &> /dev/null; then
    SHA256=$(shasum -a 256 "$ARCHIVE_NAME" | cut -d' ' -f1)
elif command -v sha256sum &> /dev/null; then
    SHA256=$(sha256sum "$ARCHIVE_NAME" | cut -d' ' -f1)
else
    print_error "Neither shasum nor sha256sum found"
    exit 1
fi

print_success "SHA256: $SHA256"

# Create checksums file
echo "$SHA256  $ARCHIVE_NAME" > "checksums-${VERSION}.txt"

# Upload function
upload_file() {
    local file="$1"
    local content_type="application/octet-stream"
    
    # Determine content type based on file extension
    if [[ "$file" == *.tar.gz ]]; then
        content_type="application/gzip"
    elif [[ "$file" == *.txt ]]; then
        content_type="text/plain"
    fi
    
    local r2_path="bash/$VERSION/$file"
    
    print_status "Uploading $file..."
    
    # Try to upload
    if wrangler r2 object put "$R2_BUCKET/$r2_path" \
        --file "$file" \
        --content-type "$content_type" \
        --cache-control "public, max-age=31536000" \
        --remote 2>/dev/null; then
        print_success "✓ $file → $R2_BASE_URL/$r2_path"
        return 0
    else
        print_error "✗ Failed to upload $file"
        return 1
    fi
}

# Upload files
print_status "Uploading to R2..."

UPLOAD_SUCCESS=0
UPLOAD_FAILED=0

if upload_file "$ARCHIVE_NAME"; then
    ((UPLOAD_SUCCESS++))
else
    ((UPLOAD_FAILED++))
fi

if upload_file "checksums-${VERSION}.txt"; then
    ((UPLOAD_SUCCESS++))
else
    ((UPLOAD_FAILED++))
fi

# Cleanup
rm -rf "$RELEASE_DIR"
rm -f "$ARCHIVE_NAME"
rm -f "checksums-${VERSION}.txt"

# Summary
echo
print_status "Upload Summary:"
print_success "$UPLOAD_SUCCESS files uploaded successfully"
if [[ $UPLOAD_FAILED -gt 0 ]]; then
    print_error "$UPLOAD_FAILED files failed to upload"
fi

if [[ $UPLOAD_FAILED -eq 0 ]]; then
    print_success "🎉 Release v$VERSION deployed to R2!"
    echo
    print_status "Homebrew formula should use:"
    echo "  url \"$R2_BASE_URL/bash/$VERSION/$ARCHIVE_NAME\""
    echo "  sha256 \"$SHA256\""
    echo
    print_status "Update the formula with these values and version $VERSION"
else
    print_error "❌ Deployment failed"
    exit 1
fi
