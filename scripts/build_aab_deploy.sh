#!/bin/bash

# build_aab_deploy.sh
# Builds Android App Bundle and deploys to Google Play Console (Internal Track)

PUBSPEC="pubspec.yaml"
ANDROID_DIR="android"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}🚀 Starting Android Build & Deploy...${NC}"

if [ ! -f "$PUBSPEC" ]; then
    echo -e "${RED}Error: $PUBSPEC not found!${NC}"
    exit 1
fi

# 1. Version Bump
echo "Checking version..."
VERSION_LINE=$(grep "^version:" $PUBSPEC)
CURRENT_VERSION=${VERSION_LINE#version: }

if [[ "$CURRENT_VERSION" == *"+"* ]]; then
    VERSION_NAME=${CURRENT_VERSION%+*}
    VERSION_CODE=${CURRENT_VERSION#*+}
else
    VERSION_NAME=$CURRENT_VERSION
    VERSION_CODE=0
fi

# Parse version
IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION_NAME"

# Check if we should increment patch
INCREMENT_PATCH=false
for arg in "$@"; do
    if [[ "$arg" == "--patch" ]]; then
        INCREMENT_PATCH=true
    fi
done

if [[ "$VERSION_CODE" =~ ^[0-9]+$ ]]; then
    NEW_CODE=$((VERSION_CODE + 1))
    
    if [ "$INCREMENT_PATCH" = true ]; then
        NEW_PATCH=$((PATCH + 1))
        NEW_VERSION_NAME="$MAJOR.$MINOR.$NEW_PATCH"
    else
        NEW_VERSION_NAME="$VERSION_NAME"
    fi
    
    NEW_VERSION="$NEW_VERSION_NAME+$NEW_CODE"
    
    echo -e "Current Version: ${YELLOW}$CURRENT_VERSION${NC}"
    echo -e "New Version:     ${GREEN}$NEW_VERSION${NC}"
    
    # Update pubspec.yaml
    sed -i '' "s/^version: .*/version: $NEW_VERSION/" $PUBSPEC
    echo "✅ Version updated in pubspec.yaml"
else
    echo -e "${RED}❌ Could not parse version. Exiting.${NC}"
    exit 1
fi

# 2. Build
echo "📦 Getting dependencies..."
flutter pub get

echo -e "${YELLOW}🏗️  Building App Bundle...${NC}"
flutter build appbundle --release

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Build failed!${NC}"
    exit 1
fi

echo "✅ Build successful"

# 3. Deploy (Fastlane)
echo -e "${YELLOW}🚀 Uploading to Google Play Console (Internal Track)...${NC}"
cd $ANDROID_DIR
fastlane internal
EXIT_CODE=$?
cd ..

if [ $EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✅ Deployment successful!${NC}"
    
    # 4. Git Commit
    echo "Committing version update..."
    git add pubspec.yaml
    git commit -m "chore: bump version to $NEW_VERSION (Android Deploy)"
    git tag "android-v$NEW_VERSION"
    echo "✅ Changes committed and tagged"
else
    echo -e "${RED}❌ Deployment failed!${NC}"
    exit 1
fi
