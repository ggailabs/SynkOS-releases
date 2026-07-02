#!/usr/bin/env bash
# SynkOS macOS installer
# Strips the quarantine attribute that causes "app is damaged" on unsigned builds.
# Usage: curl -sL https://raw.githubusercontent.com/ggailabs/SynkOS-releases/main/scripts/install-mac.sh | bash

set -euo pipefail

REPO="ggailabs/SynkOS-releases"
INSTALL_DIR="/Applications"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

die() {
  echo "✗ $*" >&2
  exit 1
}

pick_dmg_url() {
  local json page=1 url=""
  while [[ $page -le 5 ]]; do
    json=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases?per_page=10&page=${page}") || \
      die "GitHub API unreachable. Check network or https://github.com/${REPO}/releases"

    # Prefer arm64 .dmg; skip .zip, .blockmap, .yml
    url=$(printf '%s\n' "$json" | grep '"browser_download_url"' | sed 's/.*"browser_download_url": *"\([^"]*\)".*/\1/' \
      | grep -E '\.dmg$' | grep -v '\.blockmap$' | grep -E 'arm64\.dmg$|SynkOS-.*\.dmg$' | head -1 || true)

    if [[ -n "$url" ]]; then
      printf '%s' "$url"
      return 0
    fi

    # Stop if this page had no releases
    if ! printf '%s\n' "$json" | grep -q '"tag_name"'; then
      break
    fi
    page=$((page + 1))
  done
  return 1
}

echo "==> Fetching SynkOS release with macOS .dmg..."
DMG_URL="$(pick_dmg_url)" || die "No .dmg found in recent releases. Download manually: https://github.com/${REPO}/releases"

echo "==> Found: $DMG_URL"

DMG_FILE="$TMP_DIR/SynkOS.dmg"
echo "==> Downloading..."
if ! curl -fL --progress-bar "$DMG_URL" -o "$DMG_FILE"; then
  die "Download failed. Try again or grab the .dmg from https://github.com/${REPO}/releases"
fi

if [[ ! -s "$DMG_FILE" ]]; then
  die "Downloaded file is empty."
fi

# Strip quarantine BEFORE mounting — avoids "app is damaged" on Gatekeeper
echo "==> Removing quarantine attribute..."
xattr -cr "$DMG_FILE" 2>/dev/null || true

echo "==> Mounting DMG..."
MOUNT_POINT="$TMP_DIR/mount"
mkdir -p "$MOUNT_POINT"
if ! hdiutil attach "$DMG_FILE" -mountpoint "$MOUNT_POINT" -nobrowse -quiet; then
  die "Could not mount DMG (corrupt download?). Delete and re-download from releases page."
fi

APP_SRC=$(find "$MOUNT_POINT" -maxdepth 1 -name "*.app" | head -1)
if [[ -z "$APP_SRC" ]]; then
  hdiutil detach "$MOUNT_POINT" -quiet 2>/dev/null || true
  die "No .app found inside the DMG."
fi

APP_NAME=$(basename "$APP_SRC")
DEST="$INSTALL_DIR/$APP_NAME"

if [[ -d "$DEST" ]]; then
  echo "==> Removing existing $DEST..."
  rm -rf "$DEST"
fi

echo "==> Installing $APP_NAME to $INSTALL_DIR..."
cp -R "$APP_SRC" "$INSTALL_DIR/"

echo "==> Stripping quarantine from installed app..."
xattr -cr "$DEST" 2>/dev/null || true

hdiutil detach "$MOUNT_POINT" -quiet 2>/dev/null || true

echo ""
echo "✓ SynkOS installed at $DEST"
echo "  Finder → Applications → $APP_NAME"
echo "  First launch: right-click → Open if macOS still warns about the developer."