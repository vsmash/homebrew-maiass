#!/bin/bash
# updatemyass.sh - Automated script to update Homebrew formula files for MAIASS
# This script fetches the latest version, downloads the tarball, computes SHA256,
# and updates all formula files with the new version information.

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}ℹ ${1}${NC}"
}

print_success() {
    echo -e "${GREEN}✔ ${1}${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ ${1}${NC}"
}

print_error() {
    echo -e "${RED}✗ ${1}${NC}"
}

print_info "MAIASS Homebrew Formula Updater"
echo "═══════════════════════════════════════════════════════════════"

# Step 1: Fetch latest version from maiass repo package.json
print_info "Fetching latest version from maiass repository..."
PACKAGE_JSON_URL="https://raw.githubusercontent.com/vsmash/maiass/main/package.json"

# Try to fetch the package.json and extract version
if command -v curl >/dev/null 2>&1; then
    FETCHED_VERSION=$(curl -s "$PACKAGE_JSON_URL" | grep '"version"' | sed 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | tr -d '[:space:]')
elif command -v wget >/dev/null 2>&1; then
    FETCHED_VERSION=$(wget -qO- "$PACKAGE_JSON_URL" | grep '"version"' | sed 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | tr -d '[:space:]')
else
    print_error "Neither curl nor wget found. Cannot fetch version from remote."
    FETCHED_VERSION=""
fi

if [[ -n "$FETCHED_VERSION" ]]; then
    print_success "Found version: $FETCHED_VERSION"
else
    print_warning "Could not fetch version from remote repository"
    FETCHED_VERSION="4.5.1"  # Fallback to current version
fi

# Step 2: Prompt for new version with default
echo
if [[ -n "$FETCHED_VERSION" ]]; then
    read -p "Enter new version (default: $FETCHED_VERSION): " NEW_VERSION
    NEW_VERSION=${NEW_VERSION:-$FETCHED_VERSION}
else
    read -p "Enter new version: " NEW_VERSION
fi

if [[ -z "$NEW_VERSION" ]]; then
    print_error "Version cannot be empty"
    exit 1
fi

print_info "Using version: $NEW_VERSION"

# Step 3: Construct tag URL and check if it exists
TAG_URL="https://github.com/vsmash/maiass/archive/refs/tags/${NEW_VERSION}.tar.gz"
print_info "Checking if tag exists: $TAG_URL"

# Check if the tag URL exists (follow redirects)
if command -v curl >/dev/null 2>&1; then
    HTTP_STATUS=$(curl -s -L -o /dev/null -w "%{http_code}" "$TAG_URL")
elif command -v wget >/dev/null 2>&1; then
    if wget --spider -q "$TAG_URL" 2>/dev/null; then
        HTTP_STATUS="200"
    else
        HTTP_STATUS="404"
    fi
else
    print_error "Neither curl nor wget found. Cannot check tag existence."
    exit 1
fi

if [[ "$HTTP_STATUS" != "200" ]]; then
    print_error "Tag $NEW_VERSION does not exist or is not accessible (HTTP $HTTP_STATUS)"
    print_error "Please ensure the tag exists at: $TAG_URL"
    exit 1
fi

print_success "Tag exists and is accessible"

# Step 4: Download tarball and compute SHA256
print_info "Downloading tarball to compute SHA256..."
TEMP_FILE="/tmp/maiass-${NEW_VERSION}.tar.gz"

if command -v curl >/dev/null 2>&1; then
    curl -sL "$TAG_URL" -o "$TEMP_FILE"
elif command -v wget >/dev/null 2>&1; then
    wget -q "$TAG_URL" -O "$TEMP_FILE"
fi

if [[ ! -f "$TEMP_FILE" ]]; then
    print_error "Failed to download tarball"
    exit 1
fi

# Compute SHA256
if command -v shasum >/dev/null 2>&1; then
    NEW_SHA256=$(shasum -a 256 "$TEMP_FILE" | cut -d' ' -f1)
elif command -v sha256sum >/dev/null 2>&1; then
    NEW_SHA256=$(sha256sum "$TEMP_FILE" | cut -d' ' -f1)
else
    print_error "Neither shasum nor sha256sum found. Cannot compute SHA256."
    rm -f "$TEMP_FILE"
    exit 1
fi

print_success "SHA256: $NEW_SHA256"

# Clean up temp file
rm -f "$TEMP_FILE"

# Step 5: Update all formula files
print_info "Updating formula files..."

FORMULA_FILES=("Formula/maiass.rb" "Formula/myass.rb" "Formula/miass.rb")

for FORMULA_FILE in "${FORMULA_FILES[@]}"; do
    if [[ ! -f "$FORMULA_FILE" ]]; then
        print_warning "Formula file not found: $FORMULA_FILE"
        continue
    fi
    
    print_info "Updating $FORMULA_FILE..."
    
    # Create backup
    cp "$FORMULA_FILE" "${FORMULA_FILE}.backup"
    
    # Update URL
    sed -i.tmp "s|url \"https://github.com/vsmash/maiass/archive/refs/tags/[^\"]*\"|url \"$TAG_URL\"|g" "$FORMULA_FILE"
    
    # Update SHA256
    sed -i.tmp "s/sha256 \"[^\"]*\"/sha256 \"$NEW_SHA256\"/g" "$FORMULA_FILE"
    
    # Update version
    sed -i.tmp "s/version \"[^\"]*\"/version \"$NEW_VERSION\"/g" "$FORMULA_FILE"
    
    # Clean up temp files
    rm -f "${FORMULA_FILE}.tmp"
    
    print_success "Updated $FORMULA_FILE"
done

print_success "All formula files updated successfully!"
echo
print_info "Summary:"
echo "  Version: $NEW_VERSION"
echo "  URL: $TAG_URL"
echo "  SHA256: $NEW_SHA256"
echo
print_info "Backup files created with .backup extension"

# Step 6: Automated git operations with confirmations
echo
print_info "Now let's handle the git workflow..."
echo

# Show git diff
print_info "Showing changes made to formula files:"
echo
git diff --color=always
echo

# Confirm to proceed with git operations
read -p "Do you want to commit and push these changes? (y/N): " CONFIRM_GIT
if [[ "$CONFIRM_GIT" =~ ^[Yy]$ ]]; then
    # Add files
    print_info "Adding files to git..."
    git add Formula/
    
    # Commit changes
    COMMIT_MSG="Update to version $NEW_VERSION"
    print_info "Committing changes with message: '$COMMIT_MSG'"
    git commit -m "$COMMIT_MSG"
    
    # Ask about pushing
    read -p "Push to remote repository? (y/N): " CONFIRM_PUSH
    if [[ "$CONFIRM_PUSH" =~ ^[Yy]$ ]]; then
        print_info "Pushing to remote..."
        git push
        print_success "Changes pushed successfully!"
        
        # Ask about testing installation
        echo
        read -p "Test the Homebrew installation now? (y/N): " CONFIRM_TEST
        if [[ "$CONFIRM_TEST" =~ ^[Yy]$ ]]; then
            print_info "Updating Homebrew and reinstalling maiass..."
            brew update
            brew reinstall maiass
            
            print_info "Testing version detection..."
            if command -v maiass >/dev/null 2>&1; then
                maiass -v
                print_success "Installation test completed!"
            else
                print_warning "maiass command not found. You may need to restart your terminal."
            fi
        else
            print_info "Skipping installation test"
            print_warning "Remember to test later with: brew update && brew reinstall maiass"
        fi
    else
        print_info "Skipping push to remote"
        print_warning "Remember to push later with: git push"
    fi
else
    print_info "Skipping git operations"
    print_warning "Manual steps to complete:"
    echo "  1. Review the changes: git diff"
    echo "  2. Commit the changes: git add . && git commit -m 'Update to version $NEW_VERSION'"
    echo "  3. Push to remote: git push"
    echo "  4. Test the installation: brew update && brew reinstall maiass"
fi

echo
print_success "MAIASS Homebrew Formula update process completed!"