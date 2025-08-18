#!/bin/bash
# Deploy MAIASS bash release to GitHub releases (vsmash/maiass repo)
# This replaces the R2 deployment approach

set -euo pipefail
trap 'print_error "Command failed: ${BASH_COMMAND}"; exit 1' ERR

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

echo "🐙 MAIASS Bash GitHub Release Deployment"
echo "========================================"

# Configuration
# Resolve paths relative to this script for robustness regardless of cwd
# From homebrew-bashmaiass/scripts/, the built dist lives at ../../bashmaiass/dist
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MAIASS_DIST_DIR="${SCRIPT_DIR}/../../bashmaiass/dist"
GITHUB_REPO="vsmash/maiass"
GITHUB_BASE_URL="https://github.com/${GITHUB_REPO}/releases/download"
INSTALLER_SRC="${SCRIPT_DIR}/../../bashmaiass/install.sh"

# Force non-interactive gh/git behavior
export GH_PAGER=cat
export GH_NO_UPDATE_NOTIFIER=1
export GH_PROMPT_DISABLED=1
export GIT_TERMINAL_PROMPT=0

# Preflight checks
for cmd in curl jq git; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    print_error "Required command not found: $cmd"
    exit 1
  fi
done

# Acquire GitHub token for REST API (prefer env, fallback to gh)
GITHUB_TOKEN_USE="${GITHUB_TOKEN:-}"
if [[ -z "$GITHUB_TOKEN_USE" ]] && command -v gh >/dev/null 2>&1; then
  GITHUB_TOKEN_USE=$(gh auth token 2>/dev/null || true)
fi
if [[ -z "$GITHUB_TOKEN_USE" ]]; then
  print_error "No GitHub token available. Set GITHUB_TOKEN or run 'gh auth login'."
  exit 1
fi

API_ROOT="https://api.github.com"
UPLOADS_ROOT="https://uploads.github.com"

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
  api_request POST "$UPLOADS_ROOT/repos/$GITHUB_REPO/releases/$release_id/assets?name=$name" \
    -H "Content-Type: $content_type" \
    --data-binary @"$file_path" >/dev/null
}

# Accept version as first argument, else extract from package.json or maiass.sh
if [[ -n "$1" ]]; then
    VERSION="$1"
else
    # Try package.json first
    if [[ -f "$MAIASS_DIST_DIR/package.json" ]]; then
        VERSION=$(jq -r '.version' "$MAIASS_DIST_DIR/package.json")
        if [[ -z "$VERSION" || "$VERSION" == "null" ]]; then
            print_warning "Could not extract version from package.json"
        fi
    fi
    
    # Fallback to maiass.sh if package.json didn't work
    if [[ -z "$VERSION" || "$VERSION" == "null" ]]; then
        if [[ -f "$MAIASS_DIST_DIR/maiass.sh" ]]; then
            VERSION=$(grep -m1 '^# MAIASS' "$MAIASS_DIST_DIR/maiass.sh" | sed -E 's/.* v([0-9]+\.[0-9]+\.[0-9]+).*/\1/')
            if [[ -z "$VERSION" || "$VERSION" == "0.0.0" ]]; then
                print_error "Could not extract version from maiass.sh"
                exit 1
            fi
        else
            print_error "Neither package.json nor maiass.sh found in $MAIASS_DIST_DIR"
            exit 1
        fi
    fi
fi

print_status "Deploying MAIASS Bash v$VERSION to GitHub releases..."

# Check if gh CLI is available (optional)
if ! command -v gh &> /dev/null; then
    print_warning "GitHub CLI (gh) not found — continuing since REST API with GITHUB_TOKEN is used"
else
    print_status "gh CLI detected; will use it only to fetch a token if GITHUB_TOKEN is missing"
fi

# gh CLI authentication not required when GITHUB_TOKEN is provided; skipping gh auth status check

# Check if dist directory exists
print_status "Using dist directory: $MAIASS_DIST_DIR"
if [[ ! -d "$MAIASS_DIST_DIR" ]]; then
    print_error "Dist directory not found: $MAIASS_DIST_DIR"
    exit 1
fi

# Change to the dist directory to check for git repo (optional)
print_status "Navigating to dist directory..."
cd "$MAIASS_DIST_DIR" || { print_error "Failed to enter dist directory"; exit 1; }

# If dist is not a git repo, move back; tagging will be skipped
if [[ ! -d ".git" ]]; then
    print_warning "Dist directory is not a git repository; skipping commit/push in dist"
    cd - > /dev/null
else
    # Commit and push the dist files to the repo if applicable
    print_status "Committing distribution files..."
    git add .
    if git diff --staged --quiet; then
        print_warning "No changes to commit in distribution files"
    else
        git commit -m "Release v$VERSION distribution files" || true
        git push || true
        print_success "Distribution files committed and pushed"
    fi

    # Create or update the git tag
    print_status "Creating git tag v$VERSION..."
    if git tag -l | grep -q "^v$VERSION$"; then
        print_warning "Tag v$VERSION already exists, deleting and recreating..."
        git tag -d "v$VERSION" || true
        git push origin ":refs/tags/v$VERSION" 2>/dev/null || true
    fi
    git tag -a "v$VERSION" -m "Release v$VERSION" || true
    git push origin "v$VERSION" || true
    print_success "Git tag v$VERSION created and pushed"

    # Return to previous directory
    cd - > /dev/null
fi

# Commit and push the dist files to the vsmash/maiass repo
print_status "Committing distribution files to vsmash/maiass repo..."

# Add all files
git add .

# Check if there are changes to commit
if git diff --staged --quiet; then
    print_warning "No changes to commit in distribution files"
else
    git commit -m "Release v$VERSION distribution files"
    git push origin main || git push origin master
    print_success "Distribution files committed and pushed"
fi

# Create or update the git tag
print_status "Creating git tag v$VERSION..."
if git tag -l | grep -q "^v$VERSION$"; then
    print_warning "Tag v$VERSION already exists, deleting and recreating..."
    git tag -d "v$VERSION"
    git push origin ":refs/tags/v$VERSION" 2>/dev/null || true
fi

git tag -a "v$VERSION" -m "Release v$VERSION"
git push origin "v$VERSION"
print_success "Git tag v$VERSION created and pushed"

# Go back to homebrew directory
cd - > /dev/null

# Create temporary release directory for Homebrew archive
RELEASE_DIR="release-temp"
rm -rf "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR"

print_status "Creating Homebrew release archive..."

# Copy only the files needed for Homebrew installation
cp "$MAIASS_DIST_DIR/maiass.sh" "$RELEASE_DIR/"
if [[ -f "$MAIASS_DIST_DIR/bundle.sh" ]]; then
    cp "$MAIASS_DIST_DIR/bundle.sh" "$RELEASE_DIR/"
fi
if [[ -d "$MAIASS_DIST_DIR/lib" ]]; then
    cp -r "$MAIASS_DIST_DIR/lib" "$RELEASE_DIR/"
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

# Change to the maiass-dist directory to work with the git repo
cd "$MAIASS_DIST_DIR" || {
    print_error "Failed to enter maiass-dist directory"
    exit 1
}

# Check if we're in a git repository
if [[ ! -d ".git" ]]; then
    print_error "maiass-dist directory is not a git repository"
    exit 1
fi

# Commit and push the dist files to the vsmash/maiass repo
print_status "Committing distribution files to vsmash/maiass repo..."

# Add all files
git add .

# Check if there are changes to commit
if git diff --staged --quiet; then
    print_warning "No changes to commit in distribution files"
else
    git commit -m "Release v$VERSION distribution files"
    git push origin main || git push origin master
    print_success "Distribution files committed and pushed"
fi

# Create or update the git tag
print_status "Creating git tag v$VERSION..."
if git tag -l | grep -q "^v$VERSION$"; then
    print_warning "Tag v$VERSION already exists, deleting and recreating..."
    git tag -d "v$VERSION"
    git push origin ":refs/tags/v$VERSION" 2>/dev/null || true
fi

git tag -a "v$VERSION" -m "Release v$VERSION"
git push origin "v$VERSION"
print_success "Git tag v$VERSION created and pushed"

# Go back to homebrew directory
cd - > /dev/null

# Upsert GitHub release (avoid delete/create to prevent hangs)
print_status "Checking for existing GitHub release via API..."
RELEASE_ID=""
if RELEASE_JSON=$(api_request GET "$API_ROOT/repos/$GITHUB_REPO/releases/tags/v$VERSION" 2>/dev/null); then
  RELEASE_ID=$(printf '%s' "$RELEASE_JSON" | jq -r '.id // empty')
fi
if [[ -n "$RELEASE_ID" ]]; then
  print_status "Found existing release id=$RELEASE_ID"
else
  print_status "No existing release for tag v$VERSION"
fi

### Prepare install.sh asset
INSTALLER_ASSET="install.sh"
if [[ -f "$INSTALLER_SRC" ]]; then
    print_status "Including $INSTALLER_ASSET as a standalone release asset"
else
    print_warning "Installer not found at $INSTALLER_SRC; proceeding without $INSTALLER_ASSET"
    INSTALLER_ASSET=""  # unset if missing
fi

# Create or update GitHub release via API (non-interactive)
print_status "Creating/Updating GitHub release via API for v$VERSION..."

# Create release notes safely in a file to avoid shell backtick expansion
NOTES_FILE="/tmp/maiass-notes-$VERSION.md"
cat > "$NOTES_FILE" <<EOF
Release v$VERSION of MAIASS Bash

This release contains the distribution files for Homebrew installation.

## Installation

### Via Homebrew
```bash
brew tap vsmash/maiass
brew install maiass
```

### Direct Install (Linux)
```bash
curl -sSL $GITHUB_BASE_URL/v$VERSION/install.sh \| bash
```

### Direct Download (archive)
```bash
curl -L $GITHUB_BASE_URL/v$VERSION/$ARCHIVE_NAME | tar -xz
```

## Files
- **$ARCHIVE_NAME**: Homebrew installation archive (SHA256: $SHA256)
- **install.sh**: Standalone installer for Linux

For more information, visit [maiass.net](https://maiass.net)
EOF

if [[ -n "$RELEASE_ID" ]]; then
  print_status "Updating existing GitHub release (id=$RELEASE_ID) via API..."
  if api_request PATCH "$API_ROOT/repos/$GITHUB_REPO/releases/$RELEASE_ID" \
      -d "$(jq -nc --arg name "MAIASS Bash v$VERSION" --rawfile body "$NOTES_FILE" '{name:$name, body:$body, draft:false, prerelease:false}')" >/dev/null; then
    print_success "✓ GitHub release v$VERSION updated successfully"
  else
    print_error "✗ Failed to update GitHub release via API"
    exit 1
  fi
else
  # Create the release via GitHub API to avoid any interactive behavior
  print_status "Creating GitHub release via API..."
  if CREATE_JSON=$(api_request POST "$API_ROOT/repos/$GITHUB_REPO/releases" \
      -d "$(jq -nc --arg tag "v$VERSION" --arg name "MAIASS Bash v$VERSION" --rawfile body "$NOTES_FILE" '{tag_name:$tag, name:$name, body:$body, draft:false, prerelease:false}')"); then
    RELEASE_ID=$(printf '%s' "$CREATE_JSON" | jq -r '.id')
    [[ -n "$RELEASE_ID" && "$RELEASE_ID" != "null" ]] || { print_error "No release id returned"; exit 1; }
    print_success "✓ GitHub release v$VERSION created successfully"
  else
    print_error "✗ Failed to create GitHub release via API"
    exit 1
  fi
fi

# Upload assets via uploads API
upload_asset "$RELEASE_ID" "$ARCHIVE_NAME" "$ARCHIVE_NAME" "application/gzip"
if [[ -n "$INSTALLER_ASSET" ]]; then
  upload_asset "$RELEASE_ID" "$INSTALLER_SRC" "install.sh" "text/x-shellscript"
fi

# IMPORTANT: Download the file from GitHub to get the actual served checksum
# GitHub may process the file and change the checksum slightly
print_status "Verifying checksum from GitHub servers..."
GITHUB_ARCHIVE_URL="$GITHUB_BASE_URL/v$VERSION/$ARCHIVE_NAME"
TEMP_DOWNLOAD="/tmp/github-$ARCHIVE_NAME"

if command -v curl &> /dev/null; then
    curl -fsSL "$GITHUB_ARCHIVE_URL" -o "$TEMP_DOWNLOAD"
elif command -v wget &> /dev/null; then
    wget -qO "$TEMP_DOWNLOAD" "$GITHUB_ARCHIVE_URL"
else
    print_error "Neither curl nor wget found for checksum verification"
    exit 1
fi

# Calculate the actual served checksum
if command -v shasum &> /dev/null; then
    GITHUB_SHA256=$(shasum -a 256 "$TEMP_DOWNLOAD" | cut -d' ' -f1)
elif command -v sha256sum &> /dev/null; then
    GITHUB_SHA256=$(sha256sum "$TEMP_DOWNLOAD" | cut -d' ' -f1)
else
    print_error "Neither shasum nor sha256sum found"
    exit 1
fi

rm -f "$TEMP_DOWNLOAD"

if [[ "$SHA256" != "$GITHUB_SHA256" ]]; then
    print_warning "Checksum changed after GitHub upload!"
    print_warning "Local:  $SHA256"
    print_warning "GitHub: $GITHUB_SHA256"
    print_status "Using GitHub's served checksum for Homebrew formula"
    SHA256="$GITHUB_SHA256"
else
    print_success "✓ Checksum verified - matches GitHub served version"
fi

# Cleanup
rm -rf "$RELEASE_DIR"
rm -f "$ARCHIVE_NAME"

# Summary
echo
print_success "🎉 Release v$VERSION deployed to GitHub!"
echo
print_status "Homebrew formula should use:"
echo "  url \"$GITHUB_BASE_URL/v$VERSION/$ARCHIVE_NAME\""
echo "  sha256 \"$SHA256\""
echo "  version \"$VERSION\""
echo
print_status "Release URL: https://github.com/$GITHUB_REPO/releases/tag/v$VERSION"
print_status "Archive URL: $GITHUB_BASE_URL/v$VERSION/$ARCHIVE_NAME"
echo
print_status "Update the formula with these values and version $VERSION"
