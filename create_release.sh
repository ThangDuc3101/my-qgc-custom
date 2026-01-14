#!/bin/bash
# Script to create GitHub release for QGroundControl

set -e

APPIMAGE="build/Desktop_Qt_6_8_3-Release/QGroundControl-x86_64.AppImage"
APK="build/Android_Qt_6_8_3_Clang_arm64_v8a-Release/android-build-QGroundControl/build/outputs/apk/release/android-build-QGroundControl-release-signed.apk"
TAG_NAME="v$(date +'%Y.%m.%d')"
RELEASE_TITLE="Daily Build $(date +'%Y-%m-%d')"

# 1. Check gh CLI
if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI (gh) is not installed."
    echo "Please run: sudo apt install gh"
    exit 1
fi

# 2. Authenticate
if ! gh auth status &> /dev/null; then
    echo "Please login to GitHub..."
    gh auth login
fi

# 3. Create Release
echo "Creating release $TAG_NAME..."
gh release create "$TAG_NAME" \
    "$APPIMAGE" \
    "$APK" \
    --title "$RELEASE_TITLE" \
    --notes "Automated build release for QGroundControl custom version." \
    --prerelease

echo "Release created successfully!"
gh release view "$TAG_NAME"
