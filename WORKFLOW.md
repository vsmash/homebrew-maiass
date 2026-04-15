# MAIASS Bash Release Workflow

This document outlines the complete workflow for releasing MAIASS Bash and updating the Homebrew tap.

## Quick Start

### 1. Deploy Current Version
```bash
./scripts/deploy-to-r2.sh
```

### 2. Update Homebrew Formula
```bash
./scripts/update-formula.sh
```

### 3. Commit and Push
```bash
git add Formula/
git commit -m "Update maiass to v5.7.11 (R2 deployment)"
git push
```

## Complete Release Workflow

### Option A: Automated Release (Recommended)
```bash
./scripts/release-and-deploy.sh
```
This script will:
1. Prompt for new version
2. Update version in source files
3. Deploy to R2
4. Update Homebrew formula
5. Show you what to commit

### Option B: Manual Step-by-Step
```bash
# 1. Deploy to R2
./scripts/deploy-to-r2.sh [version]

# 2. Update formula
./scripts/update-formula.sh [version]

# 3. Review changes
git diff Formula/

# 4. Commit and push
git add Formula/
git commit -m "Update maiass to v[version] (R2 deployment)"
git push
```

## Testing

### Test Deployment Setup
```bash
./scripts/test-deployment.sh
```

### Test Wrangler Configuration
```bash
./scripts/test-wrangler.sh
```

## R2 Structure

After deployment, your R2 bucket will contain:
```
maiass-releases/
└── bash/
    ├── latest.json                    # Points to latest version
    └── {version}/
        ├── maiass-{version}.tar.gz    # Homebrew archive
        ├── maiass.sh                  # Direct script access
        ├── README.md                  # Documentation
        ├── package.json               # Version info
        ├── metadata.json              # Release metadata
        └── docs/                      # Documentation files
```

## Homebrew Formula

The formula will be updated with:
- **URL**: `https://releases.maiass.net/bash/{version}/maiass-{version}.tar.gz`
- **SHA256**: Computed from the archive
- **Version**: The deployed version

## Troubleshooting

### If deployment fails:
1. Check wrangler login: `wrangler whoami`
2. Test R2 access: `wrangler r2 bucket list`
3. Run test script: `./scripts/test-wrangler.sh`

### If formula update fails:
1. Check R2 metadata: `curl https://releases.maiass.net/bash/latest.json`
2. Verify archive exists: `curl -I https://releases.maiass.net/bash/{version}/maiass-{version}.tar.gz`
3. Run formula test: `brew formula Formula/maiass.rb`

## Manual Formula Update

If you need to manually update the formula:

```bash
# Edit the formula
vim Formula/maiass.rb

# Update these lines:
url "https://releases.maiass.net/bash/5.7.11/maiass-5.7.11.tar.gz"
sha256 "your-sha256-here"
version "5.7.11"

# Test the formula
brew formula Formula/maiass.rb

# Commit and push
git add Formula/
git commit -m "Update maiass to v5.7.11"
git push
```

## Version Management

- **Source**: Version is stored in `../bashmaiass/dist/package.json`
- **R2**: Version is published in `latest.json` and `{version}/metadata.json`
- **Homebrew**: Version is in `Formula/maiass.rb`

All three should stay in sync. The release scripts handle this automatically.
