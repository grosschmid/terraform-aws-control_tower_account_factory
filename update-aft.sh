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
