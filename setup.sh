#!/bin/bash
# AFT Repository Setup Script for Compliance
# This script cleans the AFT repository and creates maintenance scripts

set -e  # Exit on any error

echo "=========================================="
echo "AFT Repository Setup"
echo "=========================================="

# Verify we're in the right repository
if [[ ! -f "main.tf" ]] || [[ ! -d "modules" ]] || [[ ! -f "VERSION" ]]; then
    echo "❌ ERROR: This doesn't appear to be the AFT repository root"
    echo "   Please run this script from the terraform-aws-control_tower_account_factory directory"
    exit 1
fi

# Check if we have upstream remote configured
if ! git remote get-url upstream &>/dev/null; then
    echo "⚠️  WARNING: 'upstream' remote not found"
    echo "   Adding upstream remote to AWS original repository..."
    git remote add upstream https://github.com/aws-ia/terraform-aws-control_tower_account_factory.git
    echo "✅ Added upstream remote"
fi

echo ""
echo "🧹 Step 1: Cleaning repository..."
echo "Removing non-essential files and directories..."

# Remove safe-to-delete files/folders
rm -rf .github/
rm -f .coveragerc
rm -rf docs/
rm -rf examples/
rm -f CHANGELOG.md
rm -f CODEOWNERS
rm -f CONTRIBUTING.md  
rm -f CODE_OF_CONDUCT.md
rm -f SECURITY.md
rm -f .pre-commit-config.yaml
rm -f .terraform-docs.yml
rm -f Makefile
rm -rf scripts/

# Remove .gitignore as we'll create our own
rm -f .gitignore

echo "✅ Cleanup completed"

echo ""
echo "📝 Step 2: Creating maintenance scripts..."

# Create update script
cat > update-aft.sh << 'EOF'
#!/bin/bash
# AFT Fork Update Script
# Updates the fork with latest changes from AWS upstream

set -e

echo "=========================================="
echo "Updating AFT Fork"
echo "=========================================="

# Verify we're in the right repository
if [[ ! -f "main.tf" ]] || [[ ! -d "modules" ]] || [[ ! -f "VERSION" ]]; then
    echo "❌ ERROR: This doesn't appear to be the AFT repository root"
    exit 1
fi

# Get current version from VERSION file
CURRENT_VERSION=$(cat VERSION 2>/dev/null || echo "unknown")
echo "📋 Current version: $CURRENT_VERSION"

# Fetch latest from upstream
echo "🔄 Fetching updates from AWS upstream..."
git fetch upstream

# Check if there are new tags
echo "🏷️  Checking for new releases..."
LATEST_TAG=$(git ls-remote --tags upstream | grep -E 'refs/tags/v[0-9]+\.[0-9]+\.[0-9]+$' | sed 's/.*refs\/tags\///' | sort -V | tail -1)
echo "   Latest upstream tag: $LATEST_TAG"

# Ask user if they want to update to specific version
echo ""
echo "Available options:"
echo "1) Update to latest tag: $LATEST_TAG"
echo "2) Update to main branch (latest development)"
echo "3) Cancel update"
echo ""
read -p "Choose option [1]: " choice
choice=${choice:-1}

case $choice in
    1)
        TARGET="$LATEST_TAG"
        echo "🎯 Updating to release: $TARGET"
        ;;
    2)
        TARGET="upstream/main"
        echo "🎯 Updating to main branch"
        ;;
    3)
        echo "❌ Update cancelled"
        exit 0
        ;;
    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac

# Create update branch
BRANCH_NAME="update-$(date +%Y%m%d-%H%M%S)"
echo "🌿 Creating update branch: $BRANCH_NAME"
git checkout -b "$BRANCH_NAME"

# Merge or checkout target
if [[ $TARGET == upstream/main ]]; then
    echo "🔄 Merging upstream/main..."
    git merge upstream/main
else
    echo "🔄 Merging tag $TARGET..."
    git merge "$TARGET"
fi

# Get new version
NEW_VERSION=$(cat VERSION 2>/dev/null || echo "unknown")
echo "📋 New version: $NEW_VERSION"

# Re-run cleanup to remove any new clutter
echo "🧹 Running cleanup on updated code..."
./cleanup-aft.sh

# Check if there are changes after cleanup
if git diff --quiet; then
    echo "✅ No changes after cleanup - fork is already up to date"
else
    echo "📝 Committing cleaned update..."
    git add .
    if [[ $TARGET == upstream/main ]]; then
        git commit -m "Update AFT to main branch and apply cleanup

- Updated from upstream main branch
- Applied compliance cleanup
- Previous version: $CURRENT_VERSION
- New version: $NEW_VERSION"
    else
        git commit -m "Update AFT to $TARGET and apply cleanup

- Updated to upstream release $TARGET  
- Applied compliance cleanup
- Previous version: $CURRENT_VERSION
- New version: $NEW_VERSION"
    fi

    # Create tag
    if [[ $TARGET != upstream/main ]]; then
        TAG="${TARGET}-clean"
        echo "🏷️  Creating tag: $TAG"
        git tag "$TAG"
    fi

    echo ""
    echo "✅ Update completed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Review the changes: git log --oneline -10"
    echo "2. Push to your fork: git push origin $BRANCH_NAME"
    if [[ $TARGET != upstream/main ]]; then
        echo "3. Push tags: git push origin --tags"
        echo "4. Create PR to merge $BRANCH_NAME -> main"
        echo "5. Update your ctaft repo to use: $TAG"
    else
        echo "3. Create PR to merge $BRANCH_NAME -> main"
    fi
fi
EOF

# Create cleanup script (for future use)
cat > cleanup-aft.sh << 'EOF'
#!/bin/bash
# AFT Repository Cleanup Script for Compliance
# Removes non-essential files while preserving required legal and functional files

echo "🧹 Cleaning AFT repository for compliance..."

# Remove non-essential files/folders
rm -rf .github/ 2>/dev/null || true
rm -f .coveragerc 2>/dev/null || true
rm -rf docs/ 2>/dev/null || true
rm -rf examples/ 2>/dev/null || true
rm -f CHANGELOG.md 2>/dev/null || true
rm -f CODEOWNERS 2>/dev/null || true
rm -f CONTRIBUTING.md 2>/dev/null || true
rm -f CODE_OF_CONDUCT.md 2>/dev/null || true
rm -f SECURITY.md 2>/dev/null || true
rm -f .pre-commit-config.yaml 2>/dev/null || true
rm -f .terraform-docs.yml 2>/dev/null || true
rm -f Makefile 2>/dev/null || true
rm -rf scripts/ 2>/dev/null || true

echo "✅ Cleanup completed"
echo ""
echo "Preserved essential files:"
echo "📄 LICENSE - Apache 2.0 license (REQUIRED)"
echo "📄 NOTICE - Attribution notices (REQUIRED)"  
echo "📄 Core module files (main.tf, variables.tf, etc.)"
echo "📁 modules/ - AFT sub-modules"
echo "📁 sources/ - Template repositories" 
echo "📁 src/ - Lambda function source code"
echo "📄 VERSION, PYTHON_VERSION - Version specifications"
EOF

# Create specific .gitignore
cat > .gitignore << 'EOF'
# Terraform files
*.tfstate
*.tfstate.*
*.tfvars
.terraform/
.terraform.lock.hcl

# IDE files
.vscode/
.idea/
*.swp
*.swo
*~

# OS files
.DS_Store
Thumbs.db

# Specific
*.log
temp/
.env
EOF

# Create README for team
cat > README-SETUP.md << 'EOF'
# AFT Fork Maintenance

This is a cleaned fork of AWS Control Tower Account Factory for Terraform (AFT).

## What's Different from Upstream

This fork removes non-essential files for compliance:
- Documentation folders (`docs/`, `examples/`)
- CI/CD configurations (`.github/`, `Makefile`)
- Development tools (`.pre-commit-config.yaml`, etc.)

**Preserved essentials:**
- ✅ All functional Terraform code
- ✅ Legal files (`LICENSE`, `NOTICE`)
- ✅ Template repositories (`sources/`)
- ✅ Lambda source code (`src/`)

## Maintenance Scripts

### `update-aft.sh`
Updates the fork with latest AWS changes:
```bash
./update-aft.sh
```

### `cleanup-aft.sh`
Re-applies cleanup (used by update script):
```bash
./cleanup-aft.sh
```

## Usage in Projects

Reference your specific tagged version:
```hcl
module "aft" {
  source = "github.com/<your-org>/terraform-aws-control_tower_account_factory?ref=v1.12.0-clean"
  
  # Your configuration...
}
```

## Updating Process

1. Run `./update-aft.sh`
2. Follow the prompts to select version
3. Review changes and create PR
4. Update downstream projects to new tag

## Support

For questions about this fork, contact the Platform Core team.
For AFT issues, see: https://github.com/aws-ia/terraform-aws-control_tower_account_factory/issues
EOF

# Make scripts executable
chmod +x update-aft.sh
chmod +x cleanup-aft.sh

echo "✅ Created maintenance scripts:"
echo "   📜 update-aft.sh - Updates fork with upstream changes"
echo "   📜 cleanup-aft.sh - Applies cleanup"
echo "   📜 README-SETUP.md - Documentation for team"

echo ""
echo "🏷️  Step 3: Creating initial tag..."

# Get current version and create tag
VERSION=$(cat VERSION 2>/dev/null || echo "unknown")
TAG="v${VERSION}-clean"

echo "📋 AFT Version: $VERSION"
echo "🏷️  Tag: $TAG"

# Commit all changes
git add .
git commit -m "Initial cleanup and setup

- Applied compliance cleanup
- Created maintenance scripts (update-aft.sh, cleanup-aft.sh)
- Added documentation
- Preserved all essential functionality and legal files
- AFT Version: $VERSION"

# Create tag
git tag "$TAG"

echo ""
echo "🎉 Setup completed successfully!"
echo ""
echo "=========================================="
echo "NEXT STEPS:"
echo "=========================================="
echo "1. Push to your fork:"
echo "   git push origin main --tags"
echo ""
echo "2. Use in your ctaft repository:"
echo "   source = \"github.com/<your-org>/terraform-aws-control_tower_account_factory?ref=$TAG\""
echo ""
echo "3. For future updates, run:"
echo "   ./update-aft.sh"
echo ""
echo "4. Read README-SETUP.md for team documentation"
echo ""
echo "✅ Your AFT fork is ready!"