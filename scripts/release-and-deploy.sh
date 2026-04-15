#!/bin/bash
# MAIASS Release & Deploy Script - 6-Step Process
# 1. Commit/push maiass-dist
# 2. Tag and create GitHub release
# 3. Upload tarball and ALL loose files
# 4. Update brew formula
# 5. Commit/push homebrew-bashmaiass repo
# 6. Test homebrew

set -euo pipefail

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

# Install trap AFTER functions exist
trap 'print_error "Command failed: ${BASH_COMMAND}"' ERR

echo "🚀 MAIASS Release & Deploy (6-Step Process)"
echo "============================================"

# Configuration
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MAIASS_DIST_DIR="/Users/sysop/static/maiass-whole/maiass-dist"
HOMEBREW_REPO_DIR="/Users/sysop/static/maiass-whole/homebrew-bashmaiass"
GITHUB_REPO="vsmash/maiass"
API_ROOT="https://api.github.com"
UPLOADS_ROOT="https://uploads.github.com"

print_status "maiass-dist directory: $MAIASS_DIST_DIR"
print_status "homebrew repo directory: $HOMEBREW_REPO_DIR"

# Preflight checks
for cmd in jq curl git; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    print_error "Required command not found: $cmd"
    exit 1
  fi
done

# Get version from maiass-dist/package.json
if [[ ! -f "$MAIASS_DIST_DIR/package.json" ]]; then
  print_error "package.json not found in $MAIASS_DIST_DIR"
  exit 1
fi
VERSION=$(jq -r '.version' "$MAIASS_DIST_DIR/package.json")
if [[ -z "$VERSION" || "$VERSION" == "null" ]]; then
  print_error "Could not extract version from package.json"
  exit 1
fi
print_status "Version: $VERSION"

# GitHub token
GITHUB_TOKEN_USE="${GITHUB_TOKEN:-}"
if [[ -z "$GITHUB_TOKEN_USE" ]] && command -v gh >/dev/null 2>&1; then
  GITHUB_TOKEN_USE=$(gh auth token 2>/dev/null || true)
fi
if [[ -z "$GITHUB_TOKEN_USE" ]]; then
  print_error "GITHUB_TOKEN is required. Export GITHUB_TOKEN or run 'gh auth login'"
  exit 1
fi

# GitHub API helpers
api_request() {
  local method="$1"; shift
  local url="$1"; shift
  curl -sS --fail --retry 3 --connect-timeout 10 --max-time 120 \
    -H "Authorization: Bearer $GITHUB_TOKEN_USE" \
    -H "Accept: application/vnd.github+json" \
    -X "$method" "$url" "$@"
}

upload_asset() {
  local release_id="$1"; shift
  local file_path="$1"; shift
  local name="$1"; shift
  local content_type="$1"; shift
  print_status "Uploading asset: $name"
  if api_request POST "$UPLOADS_ROOT/repos/$GITHUB_REPO/releases/$release_id/assets?name=$name" \
    -H "Content-Type: $content_type" \
    --data-binary @"$file_path" >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

# STEP 1: Commit and push in maiass-dist
print_status "(1/6) Committing and pushing in maiass-dist..."
cd "$MAIASS_DIST_DIR"
if [[ ! -d ".git" ]]; then
  print_error "$MAIASS_DIST_DIR is not a git repository"
  exit 1
fi
git add .
if git diff --staged --quiet; then
  print_warning "No changes to commit in maiass-dist"
else
  git commit -m "Release v$VERSION distribution files"
  git push
  print_success "Pushed distribution changes"
fi

# STEP 2: Tag and create GitHub release
print_status "(2/6) Tagging v$VERSION and creating GitHub release..."
if git tag -l | grep -q "^v$VERSION$"; then
  print_warning "Tag v$VERSION exists; deleting and recreating"
  git tag -d "v$VERSION" || true
  git push origin ":refs/tags/v$VERSION" 2>/dev/null || true
fi
git tag -a "v$VERSION" -m "Release v$VERSION"
git push origin "v$VERSION"

# Check for existing release
RELEASE_ID=""
if RELEASE_JSON=$(api_request GET "$API_ROOT/repos/$GITHUB_REPO/releases/tags/v$VERSION" 2>/dev/null); then
  RELEASE_ID=$(printf '%s' "$RELEASE_JSON" | jq -r '.id // empty')
fi

# Create release notes
NOTES_FILE="/tmp/maiass-notes-$VERSION.md"
cat > "$NOTES_FILE" <<EOF
Release v$VERSION of MAIASS Bash

This release contains the distribution files for installation.

## Installation

### Via Homebrew
\`\`\`bash
brew tap vsmash/maiass
brew install maiass
\`\`\`

### Direct Install (Linux)
\`\`\`bash
curl -sSL https://github.com/vsmash/maiass/releases/download/v$VERSION/install.sh | bash
\`\`\`

For more information, visit [maiass.net](https://maiass.net)
EOF

if [[ -n "$RELEASE_ID" ]]; then
  print_status "Updating existing GitHub release (id=$RELEASE_ID)"
  api_request PATCH "$API_ROOT/repos/$GITHUB_REPO/releases/$RELEASE_ID" \
    -d "$(jq -nc --arg name "MAIASS Bash v$VERSION" --rawfile body "$NOTES_FILE" '{name:$name, body:$body, draft:false, prerelease:false}')" >/dev/null
else
  print_status "Creating new GitHub release"
  CREATE_JSON=$(api_request POST "$API_ROOT/repos/$GITHUB_REPO/releases" \
    -d "$(jq -nc --arg tag "v$VERSION" --arg name "MAIASS Bash v$VERSION" --rawfile body "$NOTES_FILE" '{tag_name:$tag, name:$name, body:$body, draft:false, prerelease:false}')")
  RELEASE_ID=$(printf '%s' "$CREATE_JSON" | jq -r '.id')
fi

if [[ -z "$RELEASE_ID" || "$RELEASE_ID" == "null" ]]; then
  print_error "Failed to get release ID"
  exit 1
fi
print_success "GitHub release ready (id=$RELEASE_ID)"

# STEP 3: Upload tarball and ALL loose files
print_status "(3/6) Creating tarball and uploading all assets..."

# Create tarball (exclude macOS extended attributes for clean Linux installs)
ARCHIVE_NAME="maiass-$VERSION.tar.gz"
if tar --version 2>/dev/null | grep -q "GNU tar"; then
  # GNU tar (Linux)
  tar -czf "/tmp/$ARCHIVE_NAME" -C "$MAIASS_DIST_DIR" .
else
  # BSD tar (macOS) - exclude extended attributes
  tar -czf "/tmp/$ARCHIVE_NAME" -C "$MAIASS_DIST_DIR" --no-xattrs .
fi
upload_asset "$RELEASE_ID" "/tmp/$ARCHIVE_NAME" "$ARCHIVE_NAME" "application/gzip"

# Upload all loose files from maiass-dist (avoid duplicates)
TEMP_FILE_LIST="/tmp/maiass-files-$VERSION.txt"
UPLOADED_NAMES_FILE="/tmp/maiass-uploaded-$VERSION.txt"
find "$MAIASS_DIST_DIR" -type f -not -path '*/.*' > "$TEMP_FILE_LIST"

# Clear uploaded names tracking file
> "$UPLOADED_NAMES_FILE"

while IFS= read -r file; do
  relative_path="${file#$MAIASS_DIST_DIR/}"
  filename="$(basename "$file")"
  
  # Skip if we've already uploaded this filename
  if grep -q "^$filename$" "$UPLOADED_NAMES_FILE" 2>/dev/null; then
    print_warning "Skipping duplicate filename: $filename"
    continue
  fi
  
  # Mark this filename as uploaded
  echo "$filename" >> "$UPLOADED_NAMES_FILE"
  
  case "$filename" in
    *.sh) content_type="text/x-shellscript" ;;
    *.json) content_type="application/json" ;;
    *.md) content_type="text/markdown" ;;
    *.txt) content_type="text/plain" ;;
    *.png|*.jpg|*.jpeg|*.gif) content_type="image/*" ;;
    *) content_type="application/octet-stream" ;;
  esac
  
  if upload_asset "$RELEASE_ID" "$file" "$filename" "$content_type"; then
    print_success "Uploaded: $filename"
  else
    print_warning "Failed to upload: $filename (continuing...)"
  fi
done < "$TEMP_FILE_LIST"

# Cleanup temp files
rm -f "$TEMP_FILE_LIST" "$UPLOADED_NAMES_FILE"

print_success "All assets uploaded"

# STEP 4: Update brew formula
print_status "(4/6) Updating Homebrew formula..."
cd "$HOMEBREW_REPO_DIR"

# Calculate SHA256 of the tarball from GitHub
GITHUB_ARCHIVE_URL="https://github.com/$GITHUB_REPO/releases/download/v$VERSION/$ARCHIVE_NAME"
curl -fsSL "$GITHUB_ARCHIVE_URL" -o "/tmp/github-$ARCHIVE_NAME"
SHA256=$(shasum -a 256 "/tmp/github-$ARCHIVE_NAME" | cut -d' ' -f1)

# Update formula
if [[ -f "scripts/update-formula.sh" ]]; then
  ./scripts/update-formula.sh "$VERSION" "$SHA256"
else
  print_warning "update-formula.sh not found; updating manually"
  sed -i '' "s/version \".*\"/version \"$VERSION\"/" Formula/maiass.rb
  sed -i '' "s/sha256 \".*\"/sha256 \"$SHA256\"/" Formula/maiass.rb
fi

print_success "Formula updated"

# STEP 5: Commit and push homebrew-bashmaiass repo
print_status "(5/6) Committing and pushing homebrew-bashmaiass repo..."
git add .
if git diff --staged --quiet; then
  print_warning "No changes to commit in homebrew repo"
else
  git commit -m "Update maiass to v$VERSION"
  git push
  print_success "Pushed homebrew changes"
fi

# STEP 6: Test homebrew (optional)
print_status "(6/6) Testing Homebrew installation..."
if command -v brew >/dev/null 2>&1; then
  print_status "Testing formula syntax..."
  if brew audit --strict Formula/maiass.rb; then
    print_success "Formula audit passed"
  else
    print_warning "Formula audit had warnings"
  fi
  
  print_status "To test installation: brew install --build-from-source Formula/maiass.rb"
else
  print_warning "Homebrew not found; skipping tests"
fi

print_success "🎉 Release v$VERSION completed successfully!"
echo
print_status "Release URL: https://github.com/$GITHUB_REPO/releases/tag/v$VERSION"
print_status "Archive URL: https://github.com/$GITHUB_REPO/releases/download/v$VERSION/$ARCHIVE_NAME"
print_status "Users can install with: brew tap vsmash/maiass && brew install maiass"
