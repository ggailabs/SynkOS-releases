#!/usr/bin/env bash
# SynkOS macOS installer
# Strips the quarantine attribute that causes "app is damaged" on unsigned builds.
# Usage: curl -sL https://raw.githubusercontent.com/ggailabs/SynkOS-releases/main/scripts/install-mac.sh | bash

set -euo pipefail

REPO="ggailabs/SynkOS-releases"
INSTALL_DIR="/Applications"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "==> Fetching latest SynkOS release..."
API_URL="https://api.github.com/repos/${REPO}/releases/latest"
DMG_URL=$(curl -fsSL "$API_URL" | grep '"browser_download_url"' | grep '\.dmg"' | head -1 | sed 's/.*"browser_download_url": *"\([^"]*\)".*/\1/')

if [[ -z "$DMG_URL" ]]; then
  echo "✗ Could not find a .dmg in the latest release. Check: https://github.com/${REPO}/releases"
  exit 1
fi

DMG_FILE="$TMP_DIR/SynkOS.dmg"
echo "==> Downloading $DMG_URL"
curl -L --progress-bar "$DMG_URL" -o "$DMG_FILE"

# Strip quarantine BEFORE mounting — avoids "app is damaged" on Gatekeeper
# for unsigned builds (Apple Silicon and Intel).
echo "==> Removing quarantine attribute..."
xattr -cr "$DMG_FILE"

echo "==> Mounting DMG..."
MOUNT_POINT="$TMP_DIR/mount"
mkdir -p "$MOUNT_POINT"
hdiutil attach "$DMG_FILE" -mountpoint "$MOUNT_POINT" -nobrowse -quiet

APP_SRC=$(find "$MOUNT_POINT" -name "*.app" -maxdepth 1 | head -1)
if [[ -z "$APP_SRC" ]]; then
  hdiutil detach "$MOUNT_POINT" -quiet 2>/dev/null || true
  echo "✗ No .app found inside the DMG."
  exit 1
fi

APP_NAME=$(basename "$APP_SRC")
DEST="$INSTALL_DIR/$APP_NAME"

if [[ -d "$DEST" ]]; then
  echo "==> Removing existing $DEST..."
  rm -rf "$DEST"
fi

echo "==> Installing $APP_NAME to $INSTALL_DIR..."
cp -r "$APP_SRC" "$INSTALL_DIR/"

echo "==> Stripping quarantine from installed app..."
xattr -cr "$DEST"

hdiutil detach "$MOUNT_POINT" -quiet 2>/dev/null || true

echo ""
echo "✓ SynkOS installed at $DEST"
echo "  Open Finder → Applications → $APP_NAME to launch."