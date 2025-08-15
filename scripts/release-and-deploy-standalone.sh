#!/bin/bash
# Minimal standalone release and deploy script for MAIASS Bash
# - Creates Homebrew-compatible archive from dist files
# - Uploads to R2 under versioned paths
# - Updates Homebrew formula
# - Uses version from dist/package.json or maiass.sh

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

echo "🚀 MAIASS Bash Release & Deploy (Standalone)"
echo "============================================="

# Config
BASHMAIASS_DIR="../bashmaiass"
FORMULA_FILE="Formula/maiass.rb"
R2_BASE_URL="https://releases.maiass.net"
R2_BUCKET="maiass-releases"

# Get version from package.json or maiass.sh
VERSION=""
if [[ -f "$BASHMAIASS_DIR/dist/package.json" ]]; then
    VERSION=$(jq -r '.version' "$BASHMAIASS_DIR/dist/package.json")
fi

if [[ -z "$VERSION" || "$VERSION" == "null" ]]; then
    if [[ -f "$BASHMAIASS_DIR/dist/maiass.sh" ]]; then
        VERSION=$(grep -m1 '^# MAIASS' "$BASHMAIASS_DIR/dist/maiass.sh" | sed -E 's/.* v([0-9]+\.[0-9]+\.[0-9]+).*/\1/')
    fi
fi

if [[ -z "$VERSION" || "$VERSION" == "0.0.0" ]]; then
    print_error "Could not extract version from package.json or maiass.sh"
    exit 1
fi

print_status "Using version: $VERSION"

# Check if dist directory exists
if [[ ! -d "$BASHMAIASS_DIR/dist" ]]; then
    print_error "Dist directory not found: $BASHMAIASS_DIR/dist"
    exit 1
fi

# Create temporary release directory for Homebrew archive
RELEASE_DIR="release-temp"
rm -rf "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR"

print_status "Creating Homebrew release archive..."

# Copy only the files needed for Homebrew installation
cp "$BASHMAIASS_DIR/dist/maiass.sh" "$RELEASE_DIR/"
if [[ -f "$BASHMAIASS_DIR/dist/bundle.sh" ]]; then
    cp "$BASHMAIASS_DIR/dist/bundle.sh" "$RELEASE_DIR/"
fi
if [[ -d "$BASHMAIASS_DIR/dist/lib" ]]; then
    cp -r "$BASHMAIASS_DIR/dist/lib" "$RELEASE_DIR/"
fi

# Create tarball for Homebrew
ARCHIVE_NAME="maiass-${VERSION}.tar.gz"
print_status "Creating Homebrew archive: $ARCHIVE_NAME"

cd "$RELEASE_DIR" || {
    print_error "Failed to enter release directory"
    exit 1
}

# Create the tarball with proper structure for Homebrew
tar -czf "../$ARCHIVE_NAME" .
cd ..

# Calculate SHA256 for Homebrew formula
print_status "Calculating SHA256 for Homebrew formula..."
if command -v shasum &> /dev/null; then
    SHA256=$(shasum -a 256 "$ARCHIVE_NAME" | cut -d' ' -f1)
elif command -v sha256sum &> /dev/null; then
    SHA256=$(sha256sum "$ARCHIVE_NAME" | cut -d' ' -f1)
else
    print_error "Neither shasum nor sha256sum found"
    exit 1
fi

print_success "Homebrew SHA256: $SHA256"

# Upload function
upload_file() {
    local file="$1"
    local r2_path="$2"
    local content_type="application/octet-stream"
    
    # Determine content type based on file extension
    if [[ "$file" == *.tar.gz ]]; then
        content_type="application/gzip"
    elif [[ "$file" == *.txt ]]; then
        content_type="text/plain"
    elif [[ "$file" == *.md ]]; then
        content_type="text/markdown"
    elif [[ "$file" == *.sh ]]; then
        content_type="text/x-shellscript"
    fi
    
    print_status "Uploading $file to $r2_path..."

    # Wrangler 4.x syntax: <bucket>/<key> as first argument, no --bucket flag
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

# Upload Homebrew archive
print_status "Uploading to R2..."
R2_URL="$R2_BASE_URL/bash/$VERSION/$ARCHIVE_NAME"

if upload_file "$ARCHIVE_NAME" "bash/$VERSION/$ARCHIVE_NAME"; then
    print_success "Homebrew archive uploaded successfully"
else
    print_error "Failed to upload Homebrew archive"
    exit 1
fi

# Upload individual files for direct access
print_status "Uploading individual files for direct access..."

# Upload maiass.sh for direct access
if upload_file "$BASHMAIASS_DIR/dist/maiass.sh" "bash/$VERSION/maiass.sh"; then
    print_success "Script uploaded for direct access"
fi

# Upload README.md
if [[ -f "$BASHMAIASS_DIR/dist/README.md" ]]; then
    upload_file "$BASHMAIASS_DIR/dist/README.md" "bash/$VERSION/README.md"
fi

# Upload package.json
if [[ -f "$BASHMAIASS_DIR/dist/package.json" ]]; then
    upload_file "$BASHMAIASS_DIR/dist/package.json" "bash/$VERSION/package.json"
fi

# Upload docs directory if it exists
if [[ -d "$BASHMAIASS_DIR/dist/docs" ]]; then
    print_status "Uploading docs directory..."
    for doc_file in "$BASHMAIASS_DIR/dist/docs"/*; do
        if [[ -f "$doc_file" ]]; then
            filename=$(basename "$doc_file")
            upload_file "$doc_file" "bash/$VERSION/docs/$filename"
        fi
    done
fi

# Cleanup
rm -rf "$RELEASE_DIR"
rm -f "$ARCHIVE_NAME"

# Update Homebrew formula
print_status "Updating Homebrew formula..."
if [[ ! -f "$FORMULA_FILE" ]]; then
    print_error "Formula file not found: $FORMULA_FILE"
    exit 1
fi

cp "$FORMULA_FILE" "$FORMULA_FILE.bak"
sed -i.tmp \
    -e "s|url \".*\"|url \"$R2_URL\"|" \
    -e "s|sha256 \".*\"|sha256 \"$SHA256\"|" \
    -e "s|version \".*\"|version \"$VERSION\"|" \
    "$FORMULA_FILE"

rm -f "$FORMULA_FILE.tmp"

print_success "Formula updated with:"
print_status "  URL: $R2_URL"
print_status "  SHA256: $SHA256"
print_status "  Version: $VERSION"

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

print_success "🎉 Release v$VERSION completed!"
echo
print_status "Next steps:"
echo "1. Review the updated formula: $FORMULA_FILE"
echo "2. Test locally: brew install --build-from-source $FORMULA_FILE"
echo "3. Commit and push changes to update the tap"
echo "4. Users can install with: brew tap vsmash/maiass && brew install maiass"
echo
print_status "R2 URL: $R2_URL"
print_status "SHA256: $SHA256"
print_status "Direct file access:"
echo "  Script: $R2_BASE_URL/bash/$VERSION/maiass.sh"
echo "  README: $R2_BASE_URL/bash/$VERSION/README.md"
echo "  Docs: $R2_BASE_URL/bash/$VERSION/docs/"
