#!/bin/bash
set -e

SIM1="A92EB0E6-595E-4E3E-B378-61812CB10CD6"  # iPhone 16
SIM2="ED15E928-8DEC-4FB2-8117-6FD78DB25949"  # iPhone 16 Plus
BUNDLE_ID="com.tracery.app"
APP_PATH="build/Build/Products/Debug-iphonesimulator/Tracery.app"

echo "==> Booting simulators..."
xcrun simctl boot "$SIM1" 2>/dev/null || true
xcrun simctl boot "$SIM2" 2>/dev/null || true
open -a Simulator

echo "==> Building..."
xcodebuild -scheme Tracery -destination "platform=iOS Simulator,id=$SIM1" -derivedDataPath build/ build

echo "==> Installing..."
xcrun simctl install "$SIM1" "$APP_PATH"
xcrun simctl install "$SIM2" "$APP_PATH"

echo "==> Launching..."
xcrun simctl launch "$SIM1" "$BUNDLE_ID"
xcrun simctl launch "$SIM2" "$BUNDLE_ID"

echo "==> Done. Both simulators running Tracery."
