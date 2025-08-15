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
ACCOUNT_ID="2ab89e92c4bd8d580f06323b9b592dd0"

# Accept version as first argument, else extract from package.json or maiass.sh
if [[ -n "$1" ]]; then
    VERSION="$1"
else
    # Try package.json first
    if [[ -f "$BASHMAIASS_DIR/dist/package.json" ]]; then
        VERSION=$(jq -r '.version' "$BASHMAIASS_DIR/dist/package.json")
        if [[ -z "$VERSION" || "$VERSION" == "null" ]]; then
            print_warning "Could not extract version from package.json"
        fi
    fi
    
    # Fallback to maiass.sh if package.json didn't work
    if [[ -z "$VERSION" || "$VERSION" == "null" ]]; then
        if [[ -f "$BASHMAIASS_DIR/dist/maiass.sh" ]]; then
            VERSION=$(grep -m1 '^# MAIASS' "$BASHMAIASS_DIR/dist/maiass.sh" | sed -E 's/.* v([0-9]+\.[0-9]+\.[0-9]+).*/\1/')
            if [[ -z "$VERSION" || "$VERSION" == "0.0.0" ]]; then
                print_error "Could not extract version from maiass.sh"
                exit 1
            fi
        else
            print_error "Neither package.json nor maiass.sh found in $BASHMAIASS_DIR/dist"
            exit 1
        fi
    fi
fi

print_status "Deploying MAIASS Bash v$VERSION to R2..."

# Check if wrangler is available
if ! command -v wrangler &> /dev/null; then
    print_error "Wrangler CLI not found"
    print_status "Install with: npm install -g wrangler"
    exit 1
fi

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

# Create tarball for Homebrew (this is what Homebrew will download)
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

# Create checksums file
echo "$SHA256  $ARCHIVE_NAME" > "checksums-${VERSION}.txt"

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
    elif [[ "$file" == *.json ]]; then
        content_type="application/json"
    elif [[ "$file" == *.sh ]]; then
        content_type="text/x-shellscript"
    fi
    
    print_status "Uploading $file to $r2_path..."

    # Wrangler 4.x syntax: <bucket>/<key> as first argument
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

# Upload Homebrew archive (this is what the formula downloads)
if upload_file "$ARCHIVE_NAME" "bash/$VERSION/$ARCHIVE_NAME"; then
    ((UPLOAD_SUCCESS++))
else
    ((UPLOAD_FAILED++))
fi

# Upload checksums
if upload_file "checksums-${VERSION}.txt" "bash/$VERSION/checksums-${VERSION}.txt"; then
    ((UPLOAD_SUCCESS++))
else
    ((UPLOAD_FAILED++))
fi

# Upload individual files for direct access (README, docs, etc.)
print_status "Uploading individual files for direct access..."

# Upload maiass.sh for direct access
if upload_file "$BASHMAIASS_DIR/dist/maiass.sh" "bash/$VERSION/maiass.sh"; then
    ((UPLOAD_SUCCESS++))
else
    ((UPLOAD_FAILED++))
fi

# Upload README.md
if [[ -f "$BASHMAIASS_DIR/dist/README.md" ]]; then
    if upload_file "$BASHMAIASS_DIR/dist/README.md" "bash/$VERSION/README.md"; then
        ((UPLOAD_SUCCESS++))
    else
        ((UPLOAD_FAILED++))
    fi
fi

# Upload package.json
if [[ -f "$BASHMAIASS_DIR/dist/package.json" ]]; then
    if upload_file "$BASHMAIASS_DIR/dist/package.json" "bash/$VERSION/package.json"; then
        ((UPLOAD_SUCCESS++))
    else
        ((UPLOAD_FAILED++))
    fi
fi

# Upload docs directory if it exists
if [[ -d "$BASHMAIASS_DIR/dist/docs" ]]; then
    print_status "Uploading docs directory..."
    for doc_file in "$BASHMAIASS_DIR/dist/docs"/*; do
        if [[ -f "$doc_file" ]]; then
            filename=$(basename "$doc_file")
            if upload_file "$doc_file" "bash/$VERSION/docs/$filename"; then
                ((UPLOAD_SUCCESS++))
            else
                ((UPLOAD_FAILED++))
            fi
        fi
    done
fi

# Create and upload release metadata JSON
print_status "Generating release metadata JSON..."
RELEASE_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
METADATA_FILE="metadata-${VERSION}.json"
cat > "$METADATA_FILE" <<EOF
{
  "product": "maiass-bash",
  "version": "$VERSION",
  "release_date": "$RELEASE_DATE",
  "archive": {
    "url": "$R2_BASE_URL/bash/$VERSION/$ARCHIVE_NAME",
    "sha256": "$SHA256",
    "filename": "$ARCHIVE_NAME"
  },
  "files": {
    "script_url": "$R2_BASE_URL/bash/$VERSION/maiass.sh",
    "readme_url": "$R2_BASE_URL/bash/$VERSION/README.md",
    "package_url": "$R2_BASE_URL/bash/$VERSION/package.json",
    "docs_url": "$R2_BASE_URL/bash/$VERSION/docs/"
  }
}
EOF

# Upload per-version metadata
if upload_file "$METADATA_FILE" "bash/$VERSION/metadata.json"; then
    ((UPLOAD_SUCCESS++))
else
    ((UPLOAD_FAILED++))
fi

# Upload top-level latest.json
if upload_file "$METADATA_FILE" "bash/latest.json"; then
    ((UPLOAD_SUCCESS++))
else
    ((UPLOAD_FAILED++))
fi

# Cleanup
rm -rf "$RELEASE_DIR"
rm -f "$ARCHIVE_NAME"
rm -f "checksums-${VERSION}.txt"
rm -f "$METADATA_FILE"

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
    echo "  version \"$VERSION\""
    echo
    print_status "Direct file access:"
    echo "  Script: $R2_BASE_URL/bash/$VERSION/maiass.sh"
    echo "  README: $R2_BASE_URL/bash/$VERSION/README.md"
    echo "  Docs: $R2_BASE_URL/bash/$VERSION/docs/"
    echo
    print_status "Update the formula with these values and version $VERSION"
else
    print_error "❌ Deployment failed"
    exit 1
fi
