#!/bin/bash

# Script to build Android App Bundle (AAB) for release with auto-increment version (Semantic Versioning Only)

PUBSPEC="pubspec.yaml"

if [ ! -f "$PUBSPEC" ]; then
    echo "Error: $PUBSPEC not found!"
    exit 1
fi

echo "Starting build process..."

# 1. Increment Version
echo "checking version..."
VERSION_LINE=$(grep "^version:" $PUBSPEC)
CURRENT_VERSION=${VERSION_LINE#version: }

# Extract semantic version X.Y.Z, ignoring build number (+...)
if [[ "$CURRENT_VERSION" == *"+"* ]]; then
    VERSION_NAME=${CURRENT_VERSION%+*}
else
    VERSION_NAME=$CURRENT_VERSION
fi

# Parse x.y.z
IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION_NAME"

# Check if PATCH is a number
if [[ "$PATCH" =~ ^[0-9]+$ ]]; then
    # Increment Patch only
    NEW_PATCH=$((PATCH + 1))
    
    # Construct new version (No +n suffix)
    NEW_VERSION="$MAJOR.$MINOR.$NEW_PATCH"
    
    echo "Current Version: $CURRENT_VERSION"
    echo "New Version:     $NEW_VERSION"
    
    # Update pubspec.yaml
    sed -i '' "s/^version: .*/version: $NEW_VERSION/" $PUBSPEC
    
    echo "✅ Version updated to $NEW_VERSION"
else
    echo "⚠️  Could not parse version. Skipping auto-increment."
    echo "Current Version: $CURRENT_VERSION"
fi

# 2. Build Process
# Get dependencies
echo "Getting dependencies..."
flutter pub get

# Build App Bundle
echo "Building App Bundle..."
flutter build appbundle --release

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo "AAB location: build/app/outputs/bundle/release/app-release.aab"
    
    # Open the output directory
    open build/app/outputs/bundle/release/
else
    echo "❌ Build failed!"
    exit 1
fi
