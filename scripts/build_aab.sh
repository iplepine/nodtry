#!/bin/bash

# Script to build Android App Bundle (AAB) for release with auto-increment version

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
# Extract version parts. Format expected: x.y.z+n
VERSION_NAME=${CURRENT_VERSION%+*}
VERSION_CODE=${CURRENT_VERSION#*+}

if [[ "$VERSION_CODE" =~ ^[0-9]+$ ]]; then
    NEW_CODE=$((VERSION_CODE + 1))
    NEW_VERSION="$VERSION_NAME+$NEW_CODE"
    
    echo "Current Version: $CURRENT_VERSION"
    echo "New Version:     $NEW_VERSION"
    
    # Update pubspec.yaml (macOS sed requires empty extension for -i)
    sed -i '' "s/^version: .*/version: $NEW_VERSION/" $PUBSPEC
    
    echo "✅ Version updated to $NEW_VERSION"
else
    echo "⚠️  Could not parse version code. Skipping auto-increment."
    echo "Current Version: $CURRENT_VERSION"
fi

# 2. Build Process
# Clean the project
# echo "Cleaning project..."
# flutter clean

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
