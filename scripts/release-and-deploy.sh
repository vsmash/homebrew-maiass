#!/bin/bash
# Automated release script for MAIASS Bash via GitHub Releases
# This script creates a release on GitHub and updates the Homebrew formula

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

# Optional debug
if [[ "${MAIASS_DEBUG:-0}" == "1" ]]; then
  set -x
fi

echo "🚀 MAIASS Bash Release & Deploy (GitHub)"
echo "========================================="
print_status "cwd: $(pwd)"

# Configuration
# Resolve paths relative to this script for robustness regardless of cwd
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# Dist lives at repo_root/bashmaiass/dist (script is in repo_root/homebrew-bashmaiass/scripts)
MAIASS_DIST_DIR="${SCRIPT_DIR}/../../bashmaiass/dist"
FORMULA_FILE="Formula/maiass.rb"

print_status "Using dist directory: $MAIASS_DIST_DIR"
print_status "Script directory: $SCRIPT_DIR"
if [[ -d "$MAIASS_DIST_DIR" ]]; then
  print_status "Dist directory exists"
else
  print_warning "Dist directory does not exist yet; will still try to resolve version from repo"
fi

# Preflight checks (jq is required for version parsing)
if ! command -v jq >/dev/null 2>&1; then
  print_error "jq is required. Install it (e.g., brew install jq) and retry."
  exit 1
fi

# Get current version from dist/package.json or fallback to repo bashmaiass/maiass.sh
print_status "Resolving version..."
CURRENT_VERSION=""
if [[ -f "$MAIASS_DIST_DIR/package.json" ]]; then
    CURRENT_VERSION=$(jq -r '.version' "$MAIASS_DIST_DIR/package.json" || true)
fi
if [[ -z "$CURRENT_VERSION" || "$CURRENT_VERSION" == "null" || "$CURRENT_VERSION" == "0.0.0" ]]; then
    REPO_MAIASS_SH="$SCRIPT_DIR/../../bashmaiass/maiass.sh"
    if [[ -f "$REPO_MAIASS_SH" ]]; then
        CURRENT_VERSION=$(grep -m1 '^# MAIASS' "$REPO_MAIASS_SH" | sed -E 's/.* v([0-9]+\.[0-9]+\.[0-9]+).*/\1/')
    fi
fi

if [[ -z "$CURRENT_VERSION" || "$CURRENT_VERSION" == "null" ]]; then
    print_error "Could not extract version from maiass.sh or package.json"
    exit 1
fi

print_status "Current version: $CURRENT_VERSION"

NEW_VERSION="$CURRENT_VERSION"
print_status "Using version: $NEW_VERSION"





# Deploy to GitHub releases
DEPLOY_SCRIPT="$(cd "$(dirname "$0")" && pwd)/deploy-to-github.sh"
print_status "Deploying to GitHub releases using: $DEPLOY_SCRIPT"
if [[ -z "${GITHUB_TOKEN:-}" ]]; then
  print_warning "GITHUB_TOKEN not set; relying on gh auth token if available"
fi
if ! bash "$DEPLOY_SCRIPT" "$NEW_VERSION"; then
    print_error "GitHub deployment failed"
    exit 1
fi

# Update Homebrew formula automatically
print_status "Updating Homebrew formula..."
if ./scripts/update-formula.sh "$NEW_VERSION"; then
    print_success "Formula updated successfully"
else
    print_warning "Formula update had issues, but deployment was successful"
    print_status "You can manually update the formula with:"
    echo "  ./scripts/update-formula.sh $NEW_VERSION"
    echo "  git add Formula/ && git commit -m \"Update maiass to v$NEW_VERSION\" && git push"
fi

print_success "🎉 Release v$NEW_VERSION completed!"
echo
print_status "Next steps:"
echo "1. Review the updated formula: $FORMULA_FILE"
echo "2. Test locally: brew install --build-from-source $FORMULA_FILE"
echo "3. Commit and push changes to update the tap"
echo "4. Users can install with: brew tap vsmash/maiass && brew install maiass"
echo
print_status "GitHub Release: https://github.com/vsmash/maiass/releases/tag/v$NEW_VERSION"
print_status "Archive URL: https://github.com/vsmash/maiass/releases/download/v$NEW_VERSION/maiass-$NEW_VERSION.tar.gz"
