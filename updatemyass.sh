#!/bin/bash
# update-formula.sh - Modular Homebrew formula updater for multiple branded tools

set -e

# --- Platform-compatible inline sed ---
portable_sed() {
  local expr="$1"
  local file="$2"

  if sed --version >/dev/null 2>&1; then
    # GNU sed
    sed -i.bak "$expr" "$file"
  else
    # BSD/macOS sed
    sed -i '' "$expr" "$file"
  fi
}

# --- Configurable by brand ---
if [[ -z "$1" ]]; then
  for brand in maiass committhis; do
    echo
    echo -e "\033[1;35m🔁 Running updater for: $brand\033[0m"
    "$0" "$brand" || exit 1  # Don't use exec — allow loop to continue
  done
  exit 0
else
  BRAND=$(echo "$1" | tr '[:upper:]' '[:lower:]')
fi

if [[ "$BRAND" == "maiass" ]]; then
  REPO="vsmash/maiass"
  FORMULAS=("Formula/maiass.rb" "Formula/myass.rb" "Formula/miass.rb")
  BINARY_NAME="maiass"
elif [[ "$BRAND" == "committhis" ]]; then
  REPO="vsmash/committhis"
  FORMULAS=("Formula/committhis.rb" "Formula/ai.rb" "Formula/committhis.rb")
  BINARY_NAME="committhis"
else
  echo "Usage: $0 <brand>"
  echo "Supported brands: maiass, committhis"
  exit 1
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() { echo -e "${BLUE}ℹ $1${NC}"; }
print_success() { echo -e "${GREEN}✔ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }

print_info "MAIASS Homebrew Formula Updater"
echo "═══════════════════════════════════════════════════════════════"

# Step 1: Fetch version
print_info "Fetching latest version from $REPO..."
PACKAGE_JSON_URL="https://raw.githubusercontent.com/$REPO/main/package.json"

if command -v curl >/dev/null 2>&1; then
  FETCHED_VERSION=$(curl -s "$PACKAGE_JSON_URL" | grep '"version"' | sed 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | tr -d '[:space:]')
elif command -v wget >/dev/null 2>&1; then
  FETCHED_VERSION=$(wget -qO- "$PACKAGE_JSON_URL" | grep '"version"' | sed 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | tr -d '[:space:]')
else
  print_error "Neither curl nor wget found."
  FETCHED_VERSION=""
fi

if [[ -n "$FETCHED_VERSION" ]]; then
  print_success "Found version: $FETCHED_VERSION"
else
  print_warning "Could not fetch version. Using fallback."
  FETCHED_VERSION="4.5.1"
fi

echo
printf "Enter new version (default: %s): " "$FETCHED_VERSION"
read NEW_VERSION
NEW_VERSION=${NEW_VERSION:-$FETCHED_VERSION}

if [[ -z "$NEW_VERSION" ]]; then
  print_error "Version cannot be empty"
  exit 1
fi

print_info "Using version: $NEW_VERSION"

TAG_URL="https://github.com/$REPO/archive/refs/tags/${NEW_VERSION}.tar.gz"
print_info "Checking if tag exists: $TAG_URL"

if command -v curl >/dev/null 2>&1; then
  HTTP_STATUS=$(curl -s -L -o /dev/null -w "%{http_code}" "$TAG_URL")
elif command -v wget >/dev/null 2>&1; then
  wget --spider -q "$TAG_URL" && HTTP_STATUS=200 || HTTP_STATUS=404
fi

if [[ "$HTTP_STATUS" != "200" ]]; then
  print_error "Tag $NEW_VERSION not accessible (HTTP $HTTP_STATUS)"
  exit 1
fi
print_success "Tag is accessible"

# Step 4: Download and compute SHA256
TEMP_FILE="/tmp/${BINARY_NAME}-${NEW_VERSION}.tar.gz"
print_info "Downloading tarball..."
curl -sL "$TAG_URL" -o "$TEMP_FILE"

[[ -f "$TEMP_FILE" ]] || { print_error "Failed to download tarball"; exit 1; }

if command -v shasum >/dev/null 2>&1; then
  NEW_SHA256=$(shasum -a 256 "$TEMP_FILE" | cut -d' ' -f1)
elif command -v sha256sum >/dev/null 2>&1; then
  NEW_SHA256=$(sha256sum "$TEMP_FILE" | cut -d' ' -f1)
else
  print_error "No SHA256 utility available."
  rm -f "$TEMP_FILE"
  exit 1
fi
rm -f "$TEMP_FILE"
print_success "SHA256: $NEW_SHA256"

# Step 5: Update formulas
for FORMULA_FILE in "${FORMULAS[@]}"; do
  if [[ ! -f "$FORMULA_FILE" ]]; then
    print_warning "Missing formula: $FORMULA_FILE"
    continue
  fi
  print_info "Updating $FORMULA_FILE"
  cp "$FORMULA_FILE" "${FORMULA_FILE}.backup"

  portable_sed "s|url \".*\"|url \"$TAG_URL\"|" "$FORMULA_FILE"
  portable_sed "s/sha256 \".*\"/sha256 \"$NEW_SHA256\"/" "$FORMULA_FILE"
  portable_sed "s/version \".*\"/version \"$NEW_VERSION\"/" "$FORMULA_FILE"

  print_success "Updated $FORMULA_FILE"
done

print_info "Showing changes:"
git diff --color=always
echo

# Step 6: Git operations
printf "Do you want to commit and push? (y/N): "
read CONFIRM_GIT
if [[ "$CONFIRM_GIT" =~ ^[Yy]$ ]]; then
  git add Formula/
  git commit -m "Update to version $NEW_VERSION"
  printf "Push to remote? (y/N): "
  read CONFIRM_PUSH
  if [[ "$CONFIRM_PUSH" =~ ^[Yy]$ ]]; then
    git push
    print_success "Changes pushed"

    # Test install
    printf "Test Homebrew install? (y/N): "
    read CONFIRM_TEST
    if [[ "$CONFIRM_TEST" =~ ^[Yy]$ ]]; then
      brew update
      brew reinstall "$BINARY_NAME"
      "$BINARY_NAME" -v || print_warning "$BINARY_NAME not found"
      printf "Uninstall $BINARY_NAME? (y/N): "
      read CONFIRM_UNINSTALL
      [[ "$CONFIRM_UNINSTALL" =~ ^[Yy]$ ]] && brew uninstall "$BINARY_NAME"
    fi
  fi
fi

echo
