#!/bin/bash
# Update Homebrew formula with R2 deployment values
# This script updates the formula with the latest R2 deployment info

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

echo "📝 Homebrew Formula Updater"
echo "=========================="

# Configuration
FORMULA_FILE="Formula/maiass.rb"
R2_BASE_URL="https://releases.maiass.net"

# Accept version as first argument, else fetch from R2 metadata
if [[ -n "$1" ]]; then
    VERSION="$1"
else
    print_status "Fetching latest version from R2 metadata..."
    R2_LATEST_JSON="$R2_BASE_URL/bash/latest.json"
    
    if command -v curl >/dev/null 2>&1; then
        LATEST_JSON=$(curl -fsSL "$R2_LATEST_JSON" 2>/dev/null || true)
    elif command -v wget >/dev/null 2>&1; then
        LATEST_JSON=$(wget -qO- "$R2_LATEST_JSON" 2>/dev/null || true)
    else
        print_error "Neither curl nor wget found"
        exit 1
    fi

    if [[ -n "$LATEST_JSON" ]]; then
        if command -v jq >/dev/null 2>&1; then
            VERSION=$(echo "$LATEST_JSON" | jq -r '.version // empty')
            ARCHIVE_URL=$(echo "$LATEST_JSON" | jq -r '.archive.url // empty')
            SHA256=$(echo "$LATEST_JSON" | jq -r '.archive.sha256 // empty')
        else
            # Fallback parsing without jq
            VERSION=$(echo "$LATEST_JSON" | sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)
            ARCHIVE_URL=$(echo "$LATEST_JSON" | sed -n 's/.*"url"[[:space:]]*:[[:space:]]*"\(https:\/\/[^\"]*\)".*/\1/p' | head -n1)
            SHA256=$(echo "$LATEST_JSON" | sed -n 's/.*"sha256"[[:space:]]*:[[:space:]]*"\([a-fA-F0-9]\{64\}\)".*/\1/p' | head -n1)
        fi
    fi

    if [[ -z "$VERSION" ]]; then
        print_error "Could not fetch version from R2 metadata"
        exit 1
    fi
fi

print_status "Using version: $VERSION"

# If we don't have the URL and SHA256 from metadata, build them
if [[ -z "$ARCHIVE_URL" ]]; then
    ARCHIVE_URL="$R2_BASE_URL/bash/$VERSION/maiass-$VERSION.tar.gz"
fi

if [[ -z "$SHA256" ]]; then
    print_status "Fetching SHA256 from R2 archive..."
    
    # Download the archive to compute SHA256
    TEMP_FILE="/tmp/maiass-$VERSION.tar.gz"
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$ARCHIVE_URL" -o "$TEMP_FILE"
    else
        wget -qO "$TEMP_FILE" "$ARCHIVE_URL"
    fi
    
    if [[ ! -f "$TEMP_FILE" ]]; then
        print_error "Failed to download archive for SHA256 computation"
        exit 1
    fi
    
    if command -v shasum >/dev/null 2>&1; then
        SHA256=$(shasum -a 256 "$TEMP_FILE" | cut -d' ' -f1)
    elif command -v sha256sum >/dev/null 2>&1; then
        SHA256=$(sha256sum "$TEMP_FILE" | cut -d' ' -f1)
    else
        print_error "No SHA256 utility available"
        rm -f "$TEMP_FILE"
        exit 1
    fi
    
    rm -f "$TEMP_FILE"
fi

print_success "Archive URL: $ARCHIVE_URL"
print_success "SHA256: $SHA256"

# Check if formula file exists
if [[ ! -f "$FORMULA_FILE" ]]; then
    print_error "Formula file not found: $FORMULA_FILE"
    exit 1
fi

# Create backup
cp "$FORMULA_FILE" "$FORMULA_FILE.backup"

# Update the formula
print_status "Updating formula: $FORMULA_FILE"

# Platform-compatible sed
if sed --version >/dev/null 2>&1; then
    # GNU sed
    sed -i.bak "s|url \".*\"|url \"$ARCHIVE_URL\"|" "$FORMULA_FILE"
    sed -i.bak "s|sha256 \".*\"|sha256 \"$SHA256\"|" "$FORMULA_FILE"
    sed -i.bak "s|version \".*\"|version \"$VERSION\"|" "$FORMULA_FILE"
    rm -f "$FORMULA_FILE.bak"
else
    # BSD/macOS sed
    sed -i '' "s|url \".*\"|url \"$ARCHIVE_URL\"|" "$FORMULA_FILE"
    sed -i '' "s|sha256 \".*\"|sha256 \"$SHA256\"|" "$FORMULA_FILE"
    sed -i '' "s|version \".*\"|version \"$VERSION\"|" "$FORMULA_FILE"
fi

print_success "Formula updated successfully!"

# Show the changes
echo
print_status "Formula changes:"
if command -v diff >/dev/null 2>&1; then
    diff -u "$FORMULA_FILE.backup" "$FORMULA_FILE" || true
else
    print_warning "diff not available, showing updated formula:"
    cat "$FORMULA_FILE"
fi

# Test formula syntax
print_status "Testing formula syntax..."
if command -v brew >/dev/null 2>&1; then
    if brew formula "$FORMULA_FILE" >/dev/null 2>&1; then
        print_success "Formula syntax is valid"
    else
        print_warning "Formula syntax check failed (but continuing)"
    fi
else
    print_warning "Homebrew not found, skipping syntax check"
fi

# Git operations
echo
printf "Do you want to commit and push the changes? (y/N): "
read CONFIRM_GIT

if [[ "$CONFIRM_GIT" =~ ^[Yy]$ ]]; then
    # Check for uncommitted changes
    if [[ -n "$(git status --porcelain)" ]]; then
        print_warning "There are uncommitted changes in the repository:"
        git status --short
        echo
        printf "Do you want to commit only the formula changes? (y/N): "
        read CONFIRM_FORMULA_ONLY
        
        if [[ "$CONFIRM_FORMULA_ONLY" =~ ^[Yy]$ ]]; then
            git add "$FORMULA_FILE"
            git commit -m "Update maiass to v$VERSION (R2 deployment)"
        else
            print_warning "Skipping git commit due to uncommitted changes"
            print_status "You can manually commit the formula changes with:"
            echo "  git add $FORMULA_FILE"
            echo "  git commit -m \"Update maiass to v$VERSION (R2 deployment)\""
            echo "  git push"
        fi
    else
        git add "$FORMULA_FILE"
        git commit -m "Update maiass to v$VERSION (R2 deployment)"
    fi
    
    # Only try to push if we successfully committed
    if [[ "$(git log --oneline -1)" == *"Update maiass to v$VERSION"* ]]; then
        printf "Push to remote? (y/N): "
        read CONFIRM_PUSH
        
        if [[ "$CONFIRM_PUSH" =~ ^[Yy]$ ]]; then
            if git push; then
                print_success "Changes pushed to remote"
                
                # Test install
                printf "Test Homebrew install? (y/N): "
                read CONFIRM_TEST
                
                if [[ "$CONFIRM_TEST" =~ ^[Yy]$ ]]; then
                    print_status "Testing Homebrew install..."
                    brew update
                    brew reinstall maiass
                    maiass --version || print_warning "maiass not found or failed to run"
                    
                    printf "Uninstall maiass? (y/N): "
                    read CONFIRM_UNINSTALL
                    if [[ "$CONFIRM_UNINSTALL" =~ ^[Yy]$ ]]; then
                        brew uninstall maiass
                        print_success "maiass uninstalled"
                    fi
                fi
            else
                print_error "Failed to push changes"
            fi
        fi
    fi
else
    print_warning "Changes not committed. You can manually commit with:"
    echo "  git add $FORMULA_FILE"
    echo "  git commit -m \"Update maiass to v$VERSION (R2 deployment)\""
    echo "  git push"
fi

# Cleanup
rm -f "$FORMULA_FILE.backup"

echo
print_success "🎉 Formula update completed!"
print_status "Version: $VERSION"
print_status "URL: $ARCHIVE_URL"
print_status "SHA256: $SHA256"
