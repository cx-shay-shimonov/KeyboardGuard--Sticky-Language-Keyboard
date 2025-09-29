# KeyboardGuard

A macOS utility that automatically switches your keyboard layout from Hebrew back to English when you stop typing for a specified period.

## What it does

KeyboardGuard monitors your keyboard activity and automatically switches from Hebrew keyboard layout back to English (ABC) when you haven't typed anything for a configurable amount of time. This prevents you from accidentally typing Hebrew characters when you meant to type in English.

### Key Features

- 🎯 **Keyboard-only tracking**: Only keyboard activity affects the idle timer (mouse movement is ignored)
- ⌨️ **Hebrew → English switching**: Specifically monitors Hebrew layout and switches to ABC layout
- ⏱️ **Configurable timeout**: Set how long to wait before switching (default: 10 seconds)
- 📊 **Real-time monitoring**: Shows current keyboard layout and idle time every 2 seconds
- 🔄 **Global monitoring**: Works regardless of which app has focus

### How it works

1. Monitors when Hebrew keyboard layout (`com.apple.keylayout.Hebrew`) is active
2. Tracks time since last keyboard input (ignores mouse movement)
3. When keyboard idle time exceeds the configured timeout, automatically switches to ABC layout
4. Logs all activity with timestamps for monitoring

## Requirements

- macOS (tested on macOS Sonoma)
- Hebrew keyboard layout enabled in System Preferences
- ABC (English) keyboard layout enabled in System Preferences
- Xcode Command Line Tools (for Swift compiler)

## Installation

### 1. Install Xcode Command Line Tools

```bash
xcode-select --install
```

### 2. Clone or Download

Download the `KeyboardGuard.swift` file to your desired directory.

### 3. Compile

```bash
swiftc KeyboardGuard.swift -o KeyboardGuard -framework Foundation -framework Carbon -framework AppKit
```

This creates an executable file named `KeyboardGuard`.

## Usage

### Basic Usage

```bash
# Use default timeout (10 seconds)
./KeyboardGuard

# Specify custom timeout in seconds
./KeyboardGuard 30

# Show help
./KeyboardGuard --help
```

### Command Line Options

- **No arguments**: Uses default timeout of 10 seconds
- **`timeout_seconds`**: Number of seconds to wait before switching (must be positive)
- **`-h` or `--help`**: Show help message with usage examples

### Sample Output

```
Keyboard Guard is starting.
Targeted language for switch: com.apple.keylayout.Hebrew
Default language: com.apple.keylayout.ABC
Idle timeout set to: 10.0 seconds.
Check interval: 2.0 seconds.
Monitoring...
Running initial check...
[2025-09-29 12:42:50 +0000] Active: Hebrew. Keyboard Idle Time: 0s.
[2025-09-29 12:42:52 +0000] Active: Hebrew. Keyboard Idle Time: 2s.
[2025-09-29 12:42:54 +0000] Active: Hebrew. Keyboard Idle Time: 4s.
[2025-09-29 12:42:56 +0000] Active: Hebrew. Keyboard Idle Time: 6s.
[2025-09-29 12:42:58 +0000] Active: Hebrew. Keyboard Idle Time: 8s.
[2025-09-29 12:43:00 +0000] Active: Hebrew. Keyboard Idle Time: 10s.
[2025-09-29 12:43:00 +0000] Idle time exceeded 10.0s. Initiating switch.
[2025-09-29 12:43:00 +0000] Successfully switched to input source: ABC
[2025-09-29 12:43:02 +0000] Active: ABC. Status OK.
```

### More Usage Examples

```bash
# Quick switching (5 seconds)
./KeyboardGuard 5

# Patient switching (60 seconds)
./KeyboardGuard 60

# Check available options
./KeyboardGuard --help
```

### Running in Background

To run KeyboardGuard in the background:

```bash
# With default timeout
nohup ./KeyboardGuard > keyboardguard.log 2>&1 &

# With custom timeout
nohup ./KeyboardGuard 30 > keyboardguard.log 2>&1 &
```

To stop the background process:

```bash
pkill KeyboardGuard
```

## Configuration

### Runtime Configuration (Recommended)

The easiest way to configure KeyboardGuard is using command-line arguments:

```bash
# Set idle timeout at runtime (no recompilation needed)
./KeyboardGuard 15    # Wait 15 seconds before switching
./KeyboardGuard 45    # Wait 45 seconds before switching
```

### Source Code Configuration

You can also modify advanced behavior by editing these constants in `KeyboardGuard.swift`:

```swift
// Keyboard layouts
let targetInputSourceID: String = "com.apple.keylayout.Hebrew" // Language to monitor
let defaultInputSourceID: String = "com.apple.keylayout.ABC"   // Language to switch to

// Default timing (can be overridden with command-line argument)
let defaultIdleTimeout: TimeInterval = 10.0 // Default timeout
let checkInterval: TimeInterval = 2.0       // How often to check (seconds)
```

After making source code changes, recompile:

```bash
swiftc KeyboardGuard.swift -o KeyboardGuard -framework Foundation -framework Carbon -framework AppKit
```

## Permissions

KeyboardGuard may request accessibility permissions to monitor keyboard events globally. If prompted:

1. Go to **System Preferences** → **Security & Privacy** → **Privacy** → **Accessibility**
2. Click the lock to make changes
3. Add KeyboardGuard to the list of allowed apps
4. Enable the checkbox next to KeyboardGuard

## Troubleshooting

### "FATAL ERROR: The default input source ID could not be found"

This means the specified keyboard layout isn't enabled. To fix:

1. Go to **System Preferences** → **Keyboard** → **Input Sources**
2. Click **+** to add missing layouts:
   - Hebrew (עברית)
   - ABC (English)
3. Ensure both layouts are enabled

### Program runs but no logs appear

- Make sure you have the required permissions (see Permissions section above)
- Try running with explicit output: `./KeyboardGuard 2>&1`

### Finding available keyboard layouts

To see what layouts are available on your system, you can create a helper script or check:

```bash
defaults read ~/Library/Preferences/com.apple.HIToolbox.plist AppleSelectedInputSources
```

## How Keyboard-Only Idle Time Works

Unlike system idle time (which resets on any mouse or keyboard activity), KeyboardGuard tracks only keyboard events:

- ✅ **Resets timer**: Key presses, key releases, modifier key changes
- ❌ **Ignores**: Mouse movement, mouse clicks, trackpad gestures

This ensures that casual mouse movement won't prevent the automatic layout switching when you're not actively typing.

## License

This project is open source. Feel free to modify and distribute as needed.

## Contributing

Found a bug or want to add a feature? Feel free to submit issues or pull requests!
