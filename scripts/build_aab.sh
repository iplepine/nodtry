#!/bin/bash

# Script to build Android App Bundle (AAB) for release with auto-increment version (Semantic Version + Build Number)

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
# CURRENT_VERSION is like 1.0.0+1 or 1.0.0

if [[ "$CURRENT_VERSION" == *"+"* ]]; then
    # Has build number
    VERSION_NAME=${CURRENT_VERSION%+*} # 1.0.0
    VERSION_CODE=${CURRENT_VERSION#*+} # 1
else
    # No build number
    VERSION_NAME=$CURRENT_VERSION
    VERSION_CODE=0 # Default start previous code as 0 so next is 1
fi

# Parse x.y.z
IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION_NAME"

# Check if PATCH and CODE are numbers
if [[ "$PATCH" =~ ^[0-9]+$ ]] && [[ "$VERSION_CODE" =~ ^[0-9]+$ ]]; then
    # Increment Patch
    NEW_PATCH=$((PATCH + 1))
    
    # Increment Build Number
    NEW_CODE=$((VERSION_CODE + 1))
    
    # Construct new version
    NEW_VERSION_NAME="$MAJOR.$MINOR.$NEW_PATCH"
    NEW_VERSION="$NEW_VERSION_NAME+$NEW_CODE"
    
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
echo "Getting dependencies..."
flutter pub get

echo "Building App Bundle..."
flutter build appbundle --release

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo "AAB location: build/app/outputs/bundle/release/app-release.aab"
    open build/app/outputs/bundle/release/
else
    echo "❌ Build failed!"
    exit 1
fi
