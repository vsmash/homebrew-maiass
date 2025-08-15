#!/bin/bash
# Minimal standalone release and deploy script for MAIASS Bash (single file, no deploy-to-r2.sh)
# - Uploads dist/maiass.sh to R2 under versioned and latest paths
# - Updates Homebrew formula
# - Uses version from dist/package.json
# - No temp dirs, no tarballs, no extra files

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

# Config
BASHMAIASS_DIR="../bashmaiass"
DIST_FILE="$BASHMAIASS_DIR/dist/maiass.sh"
PACKAGE_JSON="$BASHMAIASS_DIR/dist/package.json"
FORMULA_FILE="Formula/maiass.rb"
R2_BASE_URL="https://releases.maiass.net"
R2_BUCKET="maiass-releases"

# Get version
if [[ ! -f "$PACKAGE_JSON" ]]; then
  print_error "package.json not found: $PACKAGE_JSON"; exit 1
fi
VERSION=$(jq -r '.version' "$PACKAGE_JSON")
if [[ -z "$VERSION" || "$VERSION" == "1.0.0" ]]; then
  print_error "Could not extract version from package.json"; exit 1
fi
print_status "Using version: $VERSION"

# Check dist file
if [[ ! -f "$DIST_FILE" ]]; then
  print_error "maiass.sh not found: $DIST_FILE"; exit 1
fi

# Calculate SHA256
SHA256=$(shasum -a 256 "$DIST_FILE" | cut -d' ' -f1)
print_success "SHA256: $SHA256"

# Upload to R2 (versioned and latest)
for R2_PATH in "bash/$VERSION/maiass.sh" "bash/latest/maiass.sh"; do
  print_status "Uploading $DIST_FILE to $R2_BUCKET/$R2_PATH ..."
  if wrangler r2 object put "$R2_BUCKET/$R2_PATH" --file "$DIST_FILE" --content-type "text/x-shellscript" --cache-control "public, max-age=31536000" --remote; then
    print_success "Uploaded to $R2_BASE_URL/$R2_PATH"
  else
    print_error "Failed to upload to $R2_PATH"; exit 1
  fi
done

# Update Homebrew formula
R2_URL="$R2_BASE_URL/bash/$VERSION/maiass.sh"
print_status "Updating Homebrew formula..."
if [[ ! -f "$FORMULA_FILE" ]]; then
  print_error "Formula file not found: $FORMULA_FILE"; exit 1
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
print_status "Formula changes:"
diff -u "$FORMULA_FILE.bak" "$FORMULA_FILE" || true
rm -f "$FORMULA_FILE.bak"

print_success "🎉 Release v$VERSION completed!"
print_status "Next steps:"
echo "1. Review the updated formula: $FORMULA_FILE"
echo "2. Test locally: brew install --build-from-source $FORMULA_FILE"
echo "3. Commit and push changes to update the tap"
echo "4. Users can install with: brew tap vsmash/maiass && brew install maiass"
print_status "R2 URL: $R2_URL"
print_status "SHA256: $SHA256"
