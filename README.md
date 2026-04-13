# Tracery

A native iOS/iPadOS word-finding game. Players swipe across a 4×4 letter-dice grid to trace words. Three modes: Solo, Local Wi-Fi Multiplayer, and Table Mode (iPad as shared board).

## Requirements

- Xcode 15+
- iOS 17+ / iPadOS 17+
- [xcodegen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## Getting Started

```bash
brew install xcodegen   # if not already installed
xcodegen generate
open Tracery.xcodeproj
```

> **Dictionary:** `Tracery/Resources/twl.txt` must contain the TWL (Tournament Word List) before shipping. The bundled file is a development placeholder. Replace it with the full word list — the app picks it up automatically with no code changes needed.

## Running Tests

```bash
xcodebuild test \
  -project Tracery.xcodeproj \
  -scheme TraceryTests \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

Or press **Cmd+U** in Xcode with the `TraceryTests` scheme selected.

## Testing Local Multiplayer

MultipeerConnectivity works between simulators on the same Mac (Xcode 14+), so physical devices are not required for basic flow testing.

### Option 1: Two Simulators (easiest)

Boot a second simulator and install the app on it:

```bash
# Boot the second simulator (replace ID with any available device)
xcrun simctl boot ED15E928-8DEC-4FB2-8117-6FD78DB25949

# Open the Simulator app so both windows are visible
open -a Simulator

# Build and install on the second simulator
xcodebuild \
  -scheme Tracery \
  -destination 'id=ED15E928-8DEC-4FB2-8117-6FD78DB25949' \
  install

# Launch the app on the second simulator
xcrun simctl launch ED15E928-8DEC-4FB2-8117-6FD78DB25949 com.tracery.app
```

Then run the app normally from Xcode on the first simulator. Both instances will discover each other via MCP over the Mac's loopback network.

### Option 2: One Simulator + One Physical Device

Connect an iPhone and run the app on it via Xcode. Simultaneously run the app in a simulator. The two will discover each other over the Mac's network bridge. Both must be on the same Wi-Fi network (or the device connected via USB).

### Option 3: Two Physical iPhones (most realistic)

Build and run to each device from Xcode. Both devices must be on the same Wi-Fi network. This is the only option that exercises real peer discovery, Bluetooth fallback, and network timing behavior.

> **Note:** The `NSLocalNetworkUsageDescription` privacy prompt only fires on real devices — simulators skip it. Run on at least one physical device before submitting to the App Store to confirm the permission dialog appears correctly.
