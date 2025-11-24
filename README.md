# KeyboardGuard

A universal macOS utility that automatically switches from any non-default keyboard layout back to your preferred default language when you stop typing for a specified period.

## What it does

KeyboardGuard monitors your keyboard activity and automatically switches from ANY non-default keyboard layout back to your chosen default language when you haven't typed anything for a configurable amount of time. This prevents you from accidentally typing in the wrong language when you meant to type in your preferred language.

### Key Features

- 🎯 **System-level idle detection**: Uses IOKit HIDIdleTime for precise keyboard activity tracking
- 🌍 **Universal language support**: Works with 30+ languages as your default language
- ⏱️ **Configurable timeout**: Set how long to wait before switching (default: 10 seconds)
- 🚫 **Zero typing interruption**: Advanced algorithm prevents any mid-typing language switches
- 📊 **Real-time monitoring**: Shows current language, idle time, and typing activity status
- 🔄 **Global monitoring**: Works regardless of which app has focus
- ✅ **Language validation**: Automatically checks if languages are enabled on your system
- 🛠️ **Status checking**: Built-in tools to monitor background processes
- 🔧 **No permissions required**: Uses system APIs without needing Accessibility permissions
- 🔊 **Audio feedback**: System sound effects (Ping for success, Glass for errors)
- 🍞 **Visual notifications**: Non-intrusive toast notifications for language switches
- 📝 **Extensible configuration**: JSON configuration file allows users to add custom languages

### How it works

1. **System-level monitoring** - Uses IOKit to access HIDIdleTime for precise keyboard activity detection
2. **Universal language detection** - Any language that is NOT your default triggers the idle timer
3. **Real-time idle tracking** - Continuously monitors system idle time with sub-second precision
4. **Advanced typing detection** - Detects typing by comparing idle times and immediately resets timer
5. **Intelligent switching** - Only switches after true idle periods, never during active typing
6. **Language validation** - Validates that your chosen default language is actually enabled on your system

## Requirements

- macOS (tested on macOS Sonoma)
- At least one supported keyboard layout enabled in System Preferences
- Your desired default language enabled in System Preferences
- Xcode Command Line Tools (only needed if compiling from source)

**Language Validation**: KeyboardGuard automatically detects which languages are available on your system and validates your selections. Use `./KeyboardGuard --help` to see available languages.

**Configuration File**: KeyboardGuard uses a `languages.json` file to define supported languages and default settings. If the file doesn't exist, it will be created automatically with default values.

**Releases**: Pre-compiled binaries are available on the [Releases page](https://github.com/cx-shay-shimonov/KeyboardGuard--Sticky-Language-Keyboard/releases) for easy installation without compilation.

## Installation

### Option A: Download Pre-compiled Release (Recommended) 📦

1. **Download the latest release**:
   - Go to [Releases](https://github.com/cx-shay-shimonov/KeyboardGuard--Sticky-Language-Keyboard/releases)
   - Download `KeyboardGuard-macOS.tar.gz`

2. **Extract and install**:
   ```bash
   tar -xzf KeyboardGuard-macOS.tar.gz
   cd KeyboardGuard-*/
   ./install.sh    # Automatically handles macOS security attributes
   ```

3. **Run KeyboardGuard**:
   ```bash
   ./KeyboardGuard                    # Start with default settings
   ./KeyboardGuard --help             # Show all options
   ```

**✅ Benefits**: No compilation needed, includes all dependencies, automatically handles macOS security warnings, ready to use immediately.

### Option B: Compile from Source 🔨

1. **Install Xcode Command Line Tools**:
   ```bash
   xcode-select --install
   ```

2. **Clone the repository**:
   ```bash
   git clone https://github.com/cx-shay-shimonov/KeyboardGuard--Sticky-Language-Keyboard.git
   cd KeyboardGuard--Sticky-Language-Keyboard
   ```

3. **Compile**:
   ```bash
   swiftc KeyboardGuard.swift -o KeyboardGuard -framework Foundation -framework Carbon -framework AppKit -framework IOKit -framework AudioToolbox -framework Cocoa
   ```

**✅ Benefits**: Latest development version, ability to modify source code.

## Configuration

KeyboardGuard uses a `languages.json` configuration file to define supported languages and default settings. This file is automatically created if it doesn't exist.

### Configuration File Structure

```json
{
  "supportedLanguages": {
    "english": "com.apple.keylayout.ABC",
    "hebrew": "com.apple.keylayout.Hebrew",
    "portuguese": "com.apple.keylayout.Portuguese",
    "spanish": "com.apple.keylayout.Spanish",
    "french": "com.apple.keylayout.French"
  },
  "defaultConfiguration": {
    "idleTimeout": 10.0,
    "defaultLanguage": "english",
    "checkInterval": 2.0
  }
}
```

### Adding Custom Languages

You can add support for additional languages by editing the `languages.json` file:

1. **Find the macOS input source ID** for your language:
   ```bash
   # Method 1: Use the helper script to find input source IDs
   ./find_input_sources.swift
   
   # Method 2: Check what's available on your system
   ./KeyboardGuard --help  # Shows available languages on your system
   ```

2. **Add the language to the JSON file**:
   ```json
   "supportedLanguages": {
     "your-language": "com.apple.keylayout.YourLanguage"
   }
   ```

3. **Restart KeyboardGuard** to load the new configuration

### Configuration File Location

KeyboardGuard looks for `languages.json` in:
1. The same directory as the KeyboardGuard executable
2. The current working directory

If not found, a default configuration file will be created automatically.

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
- **`--nosound`**: Disable sound effects (default: sound enabled)
- **`--novisual`**: Disable toast notifications (default: visual enabled)
- **`-h` or `--help`**: Show help message with usage examples

**Note**: Only languages enabled in your System Preferences will work. The program validates this automatically.

### Sample Output

```
System idle time monitor initialized...
Note: Using system idle time via IOKit for reliable typing detection.
KeyboardGuard is starting.
Default language: English
Behavior: Any non-english language -> English
Idle timeout: 10.0 seconds
Sound effects: enabled (Ping/Glass)
Visual notifications: enabled (toast)
Check interval: 2.0 seconds
Monitoring...
Running initial check...
[2025-09-29 15:45:41 +0000] Active: ABC (English). Status OK.
[2025-09-29 15:45:43 +0000] Switched TO Hebrew (non-default)
Hebrew session started - idle timer initialized
[2025-09-29 15:45:43 +0000] Timer reset due to language switch
[2025-09-29 15:45:43 +0000] Active: Hebrew. Hebrew Idle Time: 0.0s. System: 0.2s. Typing: true
[2025-09-29 15:45:45 +0000] Timer reset due to typing detected (system idle: 0.1s, prev: 0.2s)
[2025-09-29 15:45:45 +0000] Active: Hebrew. Hebrew Idle Time: 0.0s. System: 0.1s. Typing: true
[2025-09-29 15:45:47 +0000] Active: Hebrew. Hebrew Idle Time: 2.0s. System: 2.1s. Typing: false
[2025-09-29 15:45:49 +0000] Active: Hebrew. Hebrew Idle Time: 4.0s. System: 4.1s. Typing: false
[2025-09-29 15:45:51 +0000] Active: Hebrew. Hebrew Idle Time: 6.0s. System: 6.1s. Typing: false
[2025-09-29 15:45:53 +0000] Active: Hebrew. Hebrew Idle Time: 8.0s. System: 8.1s. Typing: false
[2025-09-29 15:45:55 +0000] Active: Hebrew. Hebrew Idle Time: 10.0s. System: 10.1s. Typing: false
[2025-09-29 15:45:55 +0000] Hebrew idle time exceeded 10.0s. Switching to English.
[2025-09-29 15:45:55 +0000] Successfully switched to input source: ABC
Hebrew session ended
[2025-09-29 15:45:57 +0000] Active: ABC (English). Status OK.
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

# Silent mode (no sound effects)
./KeyboardGuard --nosound

# No visual notifications (sound only)
./KeyboardGuard --novisual

# Completely silent (no sound or visual)
./KeyboardGuard --nosound --novisual

# Portuguese with custom settings
./KeyboardGuard -l portuguese --nosound -t 30

# Check available options and see what languages are enabled
./KeyboardGuard --help
```

### Updating KeyboardGuard

**From Release (Recommended)**:
1. Download the latest release from the [Releases page](https://github.com/cx-shay-shimonov/KeyboardGuard--Sticky-Language-Keyboard/releases)
2. Stop any running KeyboardGuard processes: `pkill -f KeyboardGuard`
3. Replace your existing installation with the new version
4. Your `languages.json` configuration will be preserved

**From Source**:
```bash
git pull origin main
swiftc KeyboardGuard.swift -o KeyboardGuard -framework Foundation -framework Carbon -framework AppKit -framework IOKit
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
swiftc KeyboardGuard.swift -o KeyboardGuard -framework Foundation -framework Carbon -framework AppKit -framework IOKit
```

## Permissions

KeyboardGuard may request accessibility permissions to monitor keyboard events globally. If prompted:

1. Go to **System Preferences** → **Security & Privacy** → **Privacy** → **Accessibility**
2. Click the lock to make changes
3. Add KeyboardGuard to the list of allowed apps
4. Enable the checkbox next to KeyboardGuard

## Troubleshooting

### macOS Security Warning ("malware" dialog)

If you get a dialog saying *"Apple could not verify KeyboardGuard is free of malware"*:

**Solution 1 (Automatic - Recommended):**
```bash
# The install.sh script handles this automatically
tar -xzf KeyboardGuard-v1.0.0.tar.gz
cd KeyboardGuard-v1.0.0/
./install.sh    # Automatically removes quarantine attributes
./KeyboardGuard --help
```

**Solution 2 (Manual):**
```bash
# Remove quarantine attribute manually
xattr -r -d com.apple.quarantine KeyboardGuard
chmod +x KeyboardGuard
./KeyboardGuard --help
```

**Solution 3 (GUI Method):**
1. Right-click on `KeyboardGuard` → **"Open"**
2. Click **"Open"** in the security dialog
3. Run normally: `./KeyboardGuard`

**Why this happens:** The binary isn't signed with Apple Developer Program credentials ($99/year). This is normal for open-source projects.

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

### Sound Effects Not Working

If you don't hear sound effects when language switching occurs:

1. **Check system volume**: Make sure your Mac's volume is turned up
2. **Test sound files directly**:
   ```bash
   afplay /System/Library/Sounds/Ping.aiff    # Success sound
   afplay /System/Library/Sounds/Glass.aiff   # Failure sound
   ```
3. **Check sound preferences**: Go to System Preferences → Sound → Sound Effects
4. **Use silent mode if needed**: Run with `--nosound` to disable sound effects
5. **Verify compilation**: Make sure you compiled with `-framework AudioToolbox`

### Toast Notifications Not Appearing

If you don't see visual toast notifications when language switching occurs:

1. **Check if visual notifications are enabled**: Look for "Visual notifications: enabled (toast)" in startup message
2. **Test with a quick timeout**: Run `./KeyboardGuard -t 3` for faster testing
3. **Disable if not needed**: Use `--novisual` to disable toast notifications
4. **Verify compilation**: Make sure you compiled with `-framework Cocoa`
5. **Check screen position**: Toast appears in top-right corner of main screen

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
