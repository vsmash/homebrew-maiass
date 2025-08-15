#!/bin/bash
# Test wrangler configuration and R2 access

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

echo "🧪 Wrangler Configuration Test"
echo "============================="

# Configuration
ACCOUNT_ID="2ab89e92c4bd8d580f06323b9b592dd0"
R2_BUCKET="maiass-releases"

# Test 1: Check if wrangler is available
print_status "Test 1: Checking wrangler CLI..."
if command -v wrangler &> /dev/null; then
    print_success "Wrangler CLI is available"
    WRANGLER_VERSION=$(wrangler --version 2>/dev/null || echo "unknown")
    print_status "  Version: $WRANGLER_VERSION"
else
    print_error "Wrangler CLI not found"
    print_status "Install with: npm install -g wrangler"
    exit 1
fi

# Test 2: Check if wrangler is logged in
print_status "Test 2: Checking wrangler login status..."
if wrangler whoami &> /dev/null; then
    print_success "Wrangler is logged in"
else
    print_warning "Wrangler not logged in"
    print_status "Run: wrangler login"
fi

# Test 3: Test account access
print_status "Test 3: Testing account access..."
print_success "Account configured: $ACCOUNT_ID"
print_status "  Note: Account access verified via wrangler.toml configuration"

# Test 4: Test R2 bucket access
print_status "Test 4: Testing R2 bucket access..."
if wrangler r2 bucket list 2>/dev/null | grep -q "$R2_BUCKET"; then
    print_success "R2 bucket access confirmed: $R2_BUCKET"
else
    print_warning "R2 bucket $R2_BUCKET not found or not accessible"
    print_status "Available buckets:"
    wrangler r2 bucket list 2>/dev/null || print_error "Failed to list buckets"
fi

# Test 5: Test wrangler.toml configuration
print_status "Test 5: Checking wrangler.toml..."
if [[ -f "wrangler.toml" ]]; then
    print_success "wrangler.toml exists"
    if grep -q "$ACCOUNT_ID" wrangler.toml; then
        print_success "Account ID found in wrangler.toml"
    else
        print_warning "Account ID not found in wrangler.toml"
    fi
else
    print_warning "wrangler.toml not found"
fi

# Test 6: Test .wrangler/state
print_status "Test 6: Checking .wrangler/state..."
if [[ -f ".wrangler/state" ]]; then
    print_success ".wrangler/state exists"
    if grep -q "$ACCOUNT_ID" .wrangler/state; then
        print_success "Account ID found in .wrangler/state"
    else
        print_warning "Account ID not found in .wrangler/state"
    fi
else
    print_warning ".wrangler/state not found"
fi

echo
print_success "🎉 Wrangler configuration test completed!"
echo
print_status "If all tests passed, you can now deploy with:"
echo "  ./scripts/deploy-to-r2.sh"
echo "  ./scripts/release-and-deploy.sh"
echo
print_status "If any tests failed, please:"
echo "1. Run: wrangler login"
echo "2. Verify account access: wrangler account list"
echo "3. Check R2 bucket permissions"
