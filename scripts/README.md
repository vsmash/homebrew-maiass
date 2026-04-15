# MAIASS Bash Deployment Scripts

This directory contains the fixed deployment scripts for the MAIASS Bash Homebrew tap.

## Overview

The scripts have been fixed to properly:
- Extract version information from both `package.json` and `maiass.sh`
- Create Homebrew-compatible archives with the correct file structure
- Deploy to Cloudflare R2 bucket `maiass-releases` with proper organization
- Upload individual files for direct access (README, docs, etc.)
- Update the Homebrew formula with correct URLs and SHA256 hashes

## R2 Bucket Organization

Files are organized in the R2 bucket as follows:
```
maiass-releases/
└── bash/
    └── {version}/
        ├── maiass-{version}.tar.gz    # Homebrew archive
        ├── maiass.sh                   # Direct script access
        ├── README.md                   # Documentation
        ├── package.json                # Version info
        └── docs/                       # Documentation files
            ├── README.md
            ├── advanced.md
            ├── configuration.md
            └── ...
```

## Scripts

### 1. `deploy-to-r2.sh` ⭐ **CORE SCRIPT**
**Purpose:** Deploy MAIASS Bash release to Cloudflare R2

**Usage:**
```bash
./scripts/deploy-to-r2.sh [version]
```

**Features:**
- Creates Homebrew-compatible archive from `dist/` files
- Uploads archive to R2 for Homebrew formula
- Uploads individual files for direct access
- Calculates SHA256 for formula updates
- Handles version extraction from multiple sources
- Uses configured Cloudflare account ID

### 2. `release-and-deploy.sh` ⭐ **MAIN RELEASE SCRIPT**
**Purpose:** Complete release automation with version prompts

**Usage:**
```bash
./scripts/release-and-deploy.sh
```

**Features:**
- Prompts for new version
- Updates version in both `maiass.sh` and `package.json`
- Calls `deploy-to-r2.sh` for deployment
- Updates Homebrew formula automatically
- Tests formula syntax

### 3. `release-and-deploy-single.sh`
**Purpose:** Alternative release script with similar functionality

**Usage:**
```bash
./scripts/release-and-deploy-single.sh
```

### 4. `release-and-deploy-standalone.sh`
**Purpose:** Standalone release script (no external dependencies)

**Usage:**
```bash
./scripts/release-and-deploy-standalone.sh
```

### 5. `test-deployment.sh` 🧪 **TEST SCRIPT**
**Purpose:** Test deployment setup without actually deploying

**Usage:**
```bash
./scripts/test-deployment.sh
```

**Features:**
- Tests version extraction
- Creates test archive
- Validates file structure
- Checks formula syntax
- No actual deployment

### 6. `test-wrangler.sh` 🔧 **WRANGLER TEST**
**Purpose:** Test wrangler configuration and R2 access

**Usage:**
```bash
./scripts/test-wrangler.sh
```

**Features:**
- Tests wrangler CLI availability
- Checks login status
- Verifies account access
- Tests R2 bucket access
- Validates configuration files

### 7. `update-formula.sh` 📝 **FORMULA UPDATER**
**Purpose:** Update Homebrew formula with R2 deployment values

**Usage:**
```bash
./scripts/update-formula.sh [version]
```

**Features:**
- Fetches latest version from R2 metadata (`latest.json`)
- Downloads archive to compute SHA256 if needed
- Updates formula with R2 URLs and SHA256
- Tests formula syntax
- Optionally commits and pushes changes
- Interactive git workflow

## Prerequisites

1. **Wrangler CLI**: Install with `npm install -g wrangler`
2. **jq**: For JSON parsing (usually pre-installed on macOS)
3. **Homebrew**: For formula testing (optional)
4. **R2 Access**: Configured wrangler with R2 bucket access
5. **Cloudflare Account**: Account ID `2ab89e92c4bd8d580f06323b9b592dd0`

## Configuration Files

### `wrangler.toml`
Main wrangler configuration file with account and bucket settings:
```toml
name = "maiass-bash-deploy"
account_id = "2ab89e92c4bd8d580f06323b9b592dd0"

[[r2_buckets]]
binding = "MAIASS_RELEASES"
bucket_name = "maiass-releases"
```

### `.wrangler/state`
Local state file for wrangler configuration:
```json
{
  "account_id": "2ab89e92c4bd8d580f06323b9b592dd0",
  "bucket_name": "maiass-releases",
  "environment": "production"
}
```

## File Structure Requirements

The scripts expect the following structure:
```
bashmaiass/
└── dist/
    ├── maiass.sh          # Main script (required)
    ├── package.json       # Version info (required)
    ├── README.md          # Documentation (optional)
    ├── bundle.sh          # Additional script (optional)
    ├── lib/               # Library files (optional)
    └── docs/              # Documentation files (optional)
```

## Homebrew Archive Structure

The Homebrew archive contains only the files needed for installation:
```
maiass-{version}.tar.gz
├── maiass.sh
├── bundle.sh (if exists)
└── lib/ (if exists)
    └── ...
```

## Usage Examples

### Quick Test
```bash
cd homebrew-bashmaiass
./scripts/test-deployment.sh
```

### Test Wrangler Configuration
```bash
cd homebrew-bashmaiass
./scripts/test-wrangler.sh
```

### Update Formula from R2
```bash
cd homebrew-bashmaiass
./scripts/update-formula.sh
```

### Deploy Current Version
```bash
cd homebrew-bashmaiass
./scripts/deploy-to-r2.sh
```

### Full Release with New Version
```bash
cd homebrew-bashmaiass
./scripts/release-and-deploy.sh
```

### Deploy Specific Version
```bash
cd homebrew-bashmaiass
./scripts/deploy-to-r2.sh 5.7.12
```

## Troubleshooting

### Common Issues

1. **Wrangler not found**
   ```bash
   npm install -g wrangler
   ```

2. **jq not found**
   ```bash
   # macOS
   brew install jq
   
   # Ubuntu/Debian
   sudo apt-get install jq
   ```

3. **Permission denied**
   ```bash
   chmod +x scripts/*.sh
   ```

4. **R2 access issues**
   ```bash
   wrangler login
   wrangler r2 bucket list --account-id 2ab89e92c4bd8d580f06323b9b592dd0
   ```

5. **Account access issues**
   ```bash
   wrangler account list
   wrangler login
   ```

### Debug Mode

Add `set -x` to any script to enable debug output:
```bash
#!/bin/bash
set -x  # Add this line for debug output
```

## Formula Updates

The scripts automatically update `Formula/maiass.rb` with:
- New URL: `https://releases.maiass.net/bash/{version}/maiass-{version}.tar.gz`
- New SHA256: Calculated from the archive
- New version: From user input or extracted from files

## Direct File Access

After deployment, files are available at:
- Script: `https://releases.maiass.net/bash/{version}/maiass.sh`
- README: `https://releases.maiass.net/bash/{version}/README.md`
- Docs: `https://releases.maiass.net/bash/{version}/docs/`

## Version Management

The scripts handle version extraction from:
1. `package.json` (primary)
2. `maiass.sh` header comment (fallback)
3. Command line argument (override)

Version format must be semantic: `X.Y.Z` (e.g., `5.7.11`)

## Cloudflare Account Configuration

The deployment uses Cloudflare account ID `2ab89e92c4bd8d580f06323b9b592dd0` for:
- R2 bucket access
- File uploads
- Bucket management

Make sure you have access to this account and the `maiass-releases` bucket.
