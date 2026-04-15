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
GITHUB_REPO="vsmash/maiass"
GITHUB_BASE_URL="https://github.com/${GITHUB_REPO}/releases/download"

# Accept version as first argument, else fetch from GitHub releases
if [[ -n "$1" ]]; then
    VERSION="$1"
else
    print_status "Fetching latest version from GitHub releases..."
    
    if command -v gh >/dev/null 2>&1; then
        # Use GitHub CLI to get latest release
        VERSION=$(gh release list --repo "$GITHUB_REPO" --limit 1 --json tagName --jq '.[0].tagName' 2>/dev/null | sed 's/^v//')
    else
        # Fallback to GitHub API
        if command -v curl >/dev/null 2>&1; then
            LATEST_JSON=$(curl -fsSL "https://api.github.com/repos/$GITHUB_REPO/releases/latest" 2>/dev/null || true)
        elif command -v wget >/dev/null 2>&1; then
            LATEST_JSON=$(wget -qO- "https://api.github.com/repos/$GITHUB_REPO/releases/latest" 2>/dev/null || true)
        else
            print_error "Neither gh CLI, curl, nor wget found"
            exit 1
        fi

        if [[ -n "$LATEST_JSON" ]]; then
            if command -v jq >/dev/null 2>&1; then
                VERSION=$(echo "$LATEST_JSON" | jq -r '.tag_name // empty' | sed 's/^v//')
            else
                # Fallback parsing without jq
                VERSION=$(echo "$LATEST_JSON" | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"v\?\([^"]*\)".*/\1/p' | head -n1)
            fi
        fi
    fi

    if [[ -z "$VERSION" ]]; then
        print_error "Could not fetch version from GitHub releases"
        exit 1
    fi
fi

print_status "Using version: $VERSION"

# Build GitHub release URL and fetch SHA256
ARCHIVE_URL="$GITHUB_BASE_URL/v$VERSION/maiass-$VERSION.tar.gz"

print_status "Fetching SHA256 from GitHub release archive..."

# Download the archive to compute SHA256
TEMP_FILE="/tmp/maiass-$VERSION.tar.gz"
if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$ARCHIVE_URL" -o "$TEMP_FILE"
elif command -v wget >/dev/null 2>&1; then
    wget -qO "$TEMP_FILE" "$ARCHIVE_URL"
else
    print_error "Neither curl nor wget found"
    exit 1
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
    # Temporarily disable errexit so style/audit failures don't abort the script
    set +e
    brew style --formula "$FORMULA_FILE"
    STYLE_STATUS=$?
    brew audit --formula --online "$FORMULA_FILE"
    AUDIT_STATUS=$?
    set -e

    if [[ $STYLE_STATUS -eq 0 && $AUDIT_STATUS -eq 0 ]]; then
        print_success "Formula style and audit checks passed"
    else
        print_warning "Formula checks reported issues (style=$STYLE_STATUS, audit=$AUDIT_STATUS). Continuing."
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
            git commit -m "Update maiass to v$VERSION (GitHub release)"
        else
            print_warning "Skipping git commit due to uncommitted changes"
            print_status "You can manually commit the formula changes with:"
            echo "  git add $FORMULA_FILE"
            echo "  git commit -m \"Update maiass to v$VERSION (GitHub release)\""
            echo "  git push"
        fi
    else
        git add "$FORMULA_FILE"
        git commit -m "Update maiass to v$VERSION (GitHub release)"
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
    echo "  git commit -m \"Update maiass to v$VERSION (GitHub release)\""
    echo "  git push"
fi

# Cleanup
rm -f "$FORMULA_FILE.backup"

echo
print_success "🎉 Formula update completed!"
print_status "Version: $VERSION"
print_status "URL: $ARCHIVE_URL"
print_status "SHA256: $SHA256"
