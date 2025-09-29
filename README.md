# KeyboardGuard

A universal macOS utility that automatically switches from any non-default keyboard layout back to your preferred default language when you stop typing for a specified period.

## What it does

KeyboardGuard monitors your keyboard activity and automatically switches from ANY non-default keyboard layout back to your chosen default language when you haven't typed anything for a configurable amount of time. This prevents you from accidentally typing in the wrong language when you meant to type in your preferred language.

### Key Features

- 🎯 **Keyboard-only tracking**: Only keyboard activity affects the idle timer (mouse movement is ignored)
- 🌍 **Universal language support**: Works with 30+ languages as your default language
- ⏱️ **Configurable timeout**: Set how long to wait before switching (default: 10 seconds)
- 🚫 **No typing interruption**: Never switches in the middle of active typing
- 📊 **Real-time monitoring**: Shows current language, idle time, and typing activity
- 🔄 **Global monitoring**: Works regardless of which app has focus
- ✅ **Language validation**: Automatically checks if languages are enabled on your system
- 🛠️ **Status checking**: Built-in tools to monitor background processes

### How it works

1. **Monitors keyboard activity globally** - Tracks when any keyboard input occurs (ignores mouse movement)
2. **Universal language detection** - Any language that is NOT your default triggers the idle timer
3. **Smart idle tracking** - Only counts idle time when in non-default language AND you stop typing
4. **Prevents typing interruption** - Continuous typing resets the timer, no mid-sentence switching
5. **Automatic switching** - After timeout in any non-default language, switches to your default language
6. **Language validation** - Validates that your chosen default language is actually enabled on your system

## Requirements

- macOS (tested on macOS Sonoma)
- At least one supported keyboard layout enabled in System Preferences
- Your desired default language enabled in System Preferences
- Xcode Command Line Tools (for Swift compiler)

**Language Validation**: KeyboardGuard automatically detects which languages are available on your system and validates your selections. Use `./KeyboardGuard --help` to see available languages.

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

- **No arguments**: Uses default timeout of 10 seconds and English as default language
- **`-t SECONDS` or `--time SECONDS`**: Idle timeout in seconds (must be positive)
- **`-l LANGUAGE` or `--language LANGUAGE`**: Default language to switch TO
- **`-h` or `--help`**: Show help message with usage examples

**Note**: Only languages enabled in your System Preferences will work. The program validates this automatically.

### Sample Output

```
Keyboard activity monitor initialized...
Keyboard Guard is starting.
Targeted language for switch: com.apple.keylayout.Hebrew
Default language: com.apple.keylayout.ABC
Idle timeout set to: 10.0 seconds.
Check interval: 2.0 seconds.
Monitoring...
Running initial check...
[2025-09-29 13:30:04 +0000] Active: ABC. Status OK.
[2025-09-29 13:30:06 +0000] Switched TO Hebrew
[2025-09-29 13:30:06 +0000] Hebrew session started - idle timer initialized
[2025-09-29 13:30:06 +0000] Active: Hebrew. Hebrew Idle Time: 0.1s. Typing: true
[2025-09-29 13:30:08 +0000] Active: Hebrew. Hebrew Idle Time: 0.2s. Typing: true
[2025-09-29 13:30:10 +0000] Active: Hebrew. Hebrew Idle Time: 4.1s. Typing: false
[2025-09-29 13:30:12 +0000] Active: Hebrew. Hebrew Idle Time: 6.1s. Typing: false
[2025-09-29 13:30:14 +0000] Active: Hebrew. Hebrew Idle Time: 8.1s. Typing: false
[2025-09-29 13:30:16 +0000] Hebrew idle time exceeded 10.0s. Initiating switch.
[2025-09-29 13:30:16 +0000] Successfully switched to input source: ABC
[2025-09-29 13:30:16 +0000] Hebrew session ended
[2025-09-29 13:30:18 +0000] Active: ABC. Status OK.
```

### More Usage Examples

```bash
# Quick switching (5 seconds) - English default
./KeyboardGuard -t 5

# Patient switching (60 seconds) - English default  
./KeyboardGuard -t 60

# Portuguese as default language
./KeyboardGuard -l portuguese

# Spanish with custom timeout
./KeyboardGuard --language spanish --time 15

# Check available options and see what languages are enabled
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

### Checking for Background Processes

To verify if KeyboardGuard is running in the background:

```bash
# Quick check for running processes
pgrep -f KeyboardGuard

# Detailed process information
ps aux | grep KeyboardGuard | grep -v grep

# Use the comprehensive status checker (included with project)
./check_status.sh
```

**Status Checker Script:**
The project includes a `check_status.sh` script that provides a comprehensive overview:

```bash
=== KeyboardGuard Status Check ===

1. Checking for running processes...
   ✅ No KeyboardGuard processes found

2. Checking LaunchAgent status...
   ✅ No KeyboardGuard LaunchAgent loaded

3. Checking for log files...
   ✅ No log files found

4. Checking LaunchAgent file...
   ✅ No LaunchAgent file found

=== Status Check Complete ===
```

**Stop all instances:**
```bash
# Kill all running processes
pkill KeyboardGuard

# Stop LaunchAgent (if running)
launchctl stop com.user.keyboardguard
launchctl unload ~/Library/LaunchAgents/com.user.keyboardguard.plist

# Verify everything is stopped
./check_status.sh
```

## Auto-Start on Login

To have KeyboardGuard automatically start when you log into macOS, you have several options:

### Option 1: LaunchAgent (Recommended)

This is the most reliable method that integrates properly with macOS.

1. **Create the LaunchAgent file:**

```bash
mkdir -p ~/Library/LaunchAgents
```

2. **Create the plist file** at `~/Library/LaunchAgents/com.user.keyboardguard.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.keyboardguard</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/YOUR_USERNAME/Projects/KeyboardGuard/KeyboardGuard</string>
        <string>10</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/Users/YOUR_USERNAME/Projects/KeyboardGuard/keyboardguard.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/YOUR_USERNAME/Projects/KeyboardGuard/keyboardguard.log</string>
</dict>
</plist>
```

**Important:** Replace `YOUR_USERNAME` with your actual username and adjust the path to match where you compiled KeyboardGuard.

3. **Load the LaunchAgent:**

```bash
launchctl load ~/Library/LaunchAgents/com.user.keyboardguard.plist
```

4. **Manage the service:**

```bash
# Start manually
launchctl start com.user.keyboardguard

# Stop manually  
launchctl stop com.user.keyboardguard

# Disable auto-start
launchctl unload ~/Library/LaunchAgents/com.user.keyboardguard.plist
```

### Option 2: Login Items (Simple)

1. Go to **System Preferences** → **Users & Groups**
2. Select your user account
3. Click **Login Items** tab
4. Click **+** and browse to your `KeyboardGuard` executable
5. Optionally check "Hide" to run without showing a terminal window

**Note:** This method will show a terminal window unless hidden, and you can't easily pass command-line arguments.

### Option 3: Shell Profile (Terminal Users)

Add this to your `~/.zshrc` file:

```bash
# Auto-start KeyboardGuard if not already running
if ! pgrep -f "KeyboardGuard" > /dev/null; then
    nohup /Users/YOUR_USERNAME/Projects/KeyboardGuard/KeyboardGuard 10 > /tmp/keyboardguard.log 2>&1 &
fi
```

This will start KeyboardGuard whenever you open a terminal (if it's not already running).

### Customizing Auto-Start

**Change timeout for auto-start:**
In the LaunchAgent plist, modify the `ProgramArguments` section:

```xml
<key>ProgramArguments</key>
<array>
    <string>/Users/YOUR_USERNAME/Projects/KeyboardGuard/KeyboardGuard</string>
    <string>30</string>  <!-- Change this to your desired timeout -->
</array>
```

**Change log location:**
Modify the `StandardOutPath` and `StandardErrorPath` in the plist file.

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

### Language not enabled error

If you see an error like "Language 'portuguese' is not enabled on your system":

**The program now validates languages automatically** and provides helpful guidance:

```
Error: Language 'portuguese' is not enabled on your system.
Available languages on your system: english, hebrew

To enable 'portuguese' keyboard layout:
1. Go to System Preferences → Keyboard → Input Sources
2. Click + to add 'portuguese' keyboard layout
3. Run KeyboardGuard again
```

**To enable any keyboard layout:**
1. Go to **System Preferences** → **Keyboard** → **Input Sources**
2. Click **+** to add the desired language
3. Search for and add the keyboard layout
4. Run KeyboardGuard again

### Program runs but no logs appear

- Make sure you have the required permissions (see Permissions section above)
- Try running with explicit output: `./KeyboardGuard 2>&1`
- Check if multiple instances are running: `./check_status.sh`

### Understanding the logs

KeyboardGuard provides detailed logging to help you understand its behavior:

- **`Switched TO Hebrew`** - Detected language change to Hebrew, timer starts fresh
- **`Hebrew session started`** - New Hebrew idle timer initialized  
- **`Hebrew Idle Time: X.Xs. Typing: true/false`** - Shows idle time and current typing status
- **`Typing: true`** - User is actively typing (keystroke within last second)
- **`Typing: false`** - User has stopped typing, idle timer is counting up
- **`Hebrew idle time exceeded`** - Timeout reached, switching back to English
- **`Hebrew session ended`** - Hebrew session closed, timer stopped

### Switching happens during typing

If switching still occurs during active typing:

1. Check the logs show `Typing: false` when switching occurs
2. Verify Hebrew keyboard layout is properly detected
3. Increase timeout value: `./KeyboardGuard 30` (30 seconds)
4. Ensure no multiple instances are running: `./check_status.sh`

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
