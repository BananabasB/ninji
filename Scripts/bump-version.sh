#!/bin/bash
# Version bump script for Ninji
# Usage: ./bump-version.sh [major|minor|patch] [--push] [--tag]

set -e

# Check if we have a version argument
if [ $# -eq 0 ]; then
    echo "Usage: $0 [major|minor|patch] [--push] [--tag]"
    echo "Example: $0 patch --push --tag"
    exit 1
fi

VERSION_BUMP="$1"
PUSH=false
TAG=false

shift
while [ $# -gt 0 ]; do
    case "$1" in
        --push)
            PUSH=true
            ;;
        --tag)
            TAG=true
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
    shift
done

# Get current version from Info.plist or Package.swift
# For now, we'll use a simple approach with a VERSION file
VERSION_FILE="VERSION"

if [ ! -f "$VERSION_FILE" ]; then
    echo "0.0.1" > "$VERSION_FILE"
fi

CURRENT_VERSION=$(cat "$VERSION_FILE")

# Parse version
IFS='.' read -r -a VERSION_PARTS <<< "$CURRENT_VERSION"
MAJOR=${ VERSION_PARTS[0] }
MINOR=${ VERSION_PARTS[1] }
PATCH=${ VERSION_PARTS[2] }

# Bump version
case "$VERSION_BUMP" in
    major)
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        ;;
    minor)
        MINOR=$((MINOR + 1))
        PATCH=0
        ;;
    patch)
        PATCH=$((PATCH + 1))
        ;;
    *)
        echo "Invalid version bump: $VERSION_BUMP (use major, minor, or patch)"
        exit 1
        ;;
esac

NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"

echo "Bumping from $CURRENT_VERSION to $NEW_VERSION"

# Update VERSION file
echo "$NEW_VERSION" > "$VERSION_FILE"

# Update in the workflows if needed
# find .github/workflows -name "*.yml" -exec sed -i "" "s/${CURRENT_VERSION}/${NEW_VERSION}/g" {} \;

if [ "$TAG" = true ]; then
    echo "Creating git tag v${NEW_VERSION}"
    git add "$VERSION_FILE"
    git commit -m "Bump version to v${NEW_VERSION}"