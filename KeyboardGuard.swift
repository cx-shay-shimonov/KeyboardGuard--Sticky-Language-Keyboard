import Foundation
// The Carbon module contains the necessary C functions for Text Input Services (TIS).
import Carbon
// AppKit for keyboard event monitoring
import AppKit

// MARK: - Configuration

// Define the specific Input Source IDs for tracing and switching.
// These are standard IDs for macOS.
let targetInputSourceID: String = "com.apple.keylayout.Hebrew" // The language to trace (Hebrew)
let defaultInputSourceID: String = "com.apple.keylayout.ABC"    // The language to switch back to (ABC/English)

// The default duration (in seconds) the keyboard must be idle before switching back to default.
let defaultIdleTimeout: TimeInterval = 10.0 // Default: 10 seconds

// The interval (in seconds) to check the system idle time.
let checkInterval: TimeInterval = 2.0 // Check every 2 seconds for more responsive testing

// MARK: - TIS (Text Input Services) Utilities

/// Finds the TISInputSourceRef for a given input source ID (e.g., "com.apple.keylayout.US").
/// - Parameter identifier: The input source ID string.
/// - Returns: A TISInputSourceRef or nil if not found.
func findInputSource(by identifier: String) -> TISInputSource? {
    // Create a dictionary to search for the specific input source property.
    let filter = [
        kTISPropertyInputSourceID: identifier
    ] as CFDictionary

    // Create a list of matching input sources.
    guard let sourceList = TISCreateInputSourceList(filter, false)?.takeRetainedValue() as? [TISInputSource] else {
        return nil
    }

    // Since IDs should be unique, we return the first match.
    return sourceList.first
}

/// Gets the currently selected keyboard input source ID.
/// - Returns: The string identifier of the current input source, or nil on failure.
func getCurrentInputSourceID() -> String? {
    guard let inputSource = TISCopyCurrentKeyboardInputSource()?.takeUnretainedValue() else {
        return nil
    }

    // Get the property dictionary for the input source.
    guard let properties = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceID) else {
        return nil
    }

    // Cast the CFTypeRef to String.
    return Unmanaged<CFString>.fromOpaque(properties).takeUnretainedValue() as String
}

/// Switches the keyboard input source to the provided TISInputSourceRef.
/// - Parameter source: The TISInputSourceRef to switch to.
func selectInputSource(_ source: TISInputSource) {
    let status = TISSelectInputSource(source)
    if status == noErr {
        let nameProperty = TISGetInputSourceProperty(source, kTISPropertyLocalizedName)
        let name = nameProperty != nil ? Unmanaged<CFString>.fromOpaque(nameProperty!).takeUnretainedValue() as String : "Unknown"
        print("[\(Date())] Successfully switched to input source: \(name)")
    } else {
        print("[\(Date())] Failed to switch input source. Status: \(status)")
    }
}

// MARK: - Keyboard Idle Time Utility

/// Tracks when keyboard activity occurs (separate from Hebrew idle timing)
class KeyboardActivityMonitor {
    private var lastKeyboardEventTime: Date = Date()
    private var eventMonitor: Any?
    
    init() {
        setupKeyboardMonitor()
        print("Keyboard activity monitor initialized...")
    }
    
    deinit {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
    
    /// Sets up a global keyboard event monitor to track keyboard activity
    private func setupKeyboardMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .keyUp, .flagsChanged]) { [weak self] event in
            self?.lastKeyboardEventTime = Date()
        }
        
        // Also monitor local events (when app has focus)
        NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp, .flagsChanged]) { [weak self] event in
            self?.lastKeyboardEventTime = Date()
            return event
        }
    }
    
    /// Gets the time since the last keyboard event in seconds
    func getTimeSinceLastKeyboardEvent() -> TimeInterval {
        return Date().timeIntervalSince(lastKeyboardEventTime)
    }
}

/// Manages Hebrew-specific idle timing
class HebrewIdleTimer {
    private var hebrewStartTime: Date?
    private var lastActivityInHebrew: Date?
    
    /// Call when switching TO Hebrew
    func startHebrewSession() {
        hebrewStartTime = Date()
        lastActivityInHebrew = Date()
        print("Hebrew session started - idle timer initialized")
    }
    
    /// Call when there's keyboard activity while in Hebrew
    func recordHebrewActivity() {
        lastActivityInHebrew = Date()
    }
    
    /// Get idle time since last activity in Hebrew (only valid if Hebrew session is active)
    func getHebrewIdleTime() -> TimeInterval? {
        guard let lastActivity = lastActivityInHebrew else { return nil }
        return Date().timeIntervalSince(lastActivity)
    }
    
    /// Stop Hebrew session (when switching away from Hebrew)
    func stopHebrewSession() {
        hebrewStartTime = nil
        lastActivityInHebrew = nil
        print("Hebrew session ended")
    }
    
    /// Returns true if currently in a Hebrew session
    func isInHebrewSession() -> Bool {
        return hebrewStartTime != nil
    }
}

// MARK: - Main Logic

class KeyboardGuard {
    // Store a reference to the default source once to avoid repeated lookups.
    var defaultSource: TISInputSource?
    // Monitor keyboard activity globally
    private let keyboardMonitor = KeyboardActivityMonitor()
    // Manage Hebrew-specific idle timing
    private let hebrewTimer = HebrewIdleTimer()
    // Configurable idle timeout
    private let idleTimeout: TimeInterval
    // Track previous language to detect switches
    private var previousLanguageID: String?
    
    init(idleTimeout: TimeInterval) {
        self.idleTimeout = idleTimeout
        // Look up the default input source once at startup.
        defaultSource = findInputSource(by: defaultInputSourceID)
    }

    /// The core function that checks the current state and switches the keyboard if necessary.
    @objc func runLanguageCheck() {
    guard let currentID = getCurrentInputSourceID() else {
        print("[\(Date())] Could not determine current input source ID.")
        return
    }

    let currentInputSource = TISCopyCurrentKeyboardInputSource()?.takeUnretainedValue()
    let nameProperty = currentInputSource != nil ? TISGetInputSourceProperty(currentInputSource!, kTISPropertyLocalizedName) : nil
    let currentName = nameProperty != nil ? Unmanaged<CFString>.fromOpaque(nameProperty!).takeUnretainedValue() as String : "Unknown"

    // Detect language changes
    let switchedToHebrew = currentID == targetInputSourceID && previousLanguageID != targetInputSourceID
    let switchedAwayFromHebrew = previousLanguageID == targetInputSourceID && currentID != targetInputSourceID
    
    // Get current keyboard activity status
    let timeSinceLastKeyboard = keyboardMonitor.getTimeSinceLastKeyboardEvent()
    let isCurrentlyTyping = timeSinceLastKeyboard < 1.0 // Consider "typing" if keystroke within 1 second
    
    // Handle Hebrew session management
    if switchedToHebrew {
        print("[\(Date())] Switched TO Hebrew")
        hebrewTimer.startHebrewSession()
    } else if switchedAwayFromHebrew {
        hebrewTimer.stopHebrewSession()
    }
    
    // Update previous language for next check
    previousLanguageID = currentID

    // Main logic
    if currentID == targetInputSourceID {
        // Currently in Hebrew
        
        // Record activity if user is currently typing
        if isCurrentlyTyping {
            hebrewTimer.recordHebrewActivity()
        }
        
        // Get Hebrew idle time
        if let hebrewIdleTime = hebrewTimer.getHebrewIdleTime() {
            print("[\(Date())] Active: \(currentName). Hebrew Idle Time: \(String(format: "%.1f", hebrewIdleTime))s. Typing: \(isCurrentlyTyping)")
            
            // Switch if idle long enough
            if hebrewIdleTime >= idleTimeout {
                print("[\(Date())] Hebrew idle time exceeded \(idleTimeout)s. Initiating switch.")
                
                guard let sourceToSwitchTo = defaultSource else {
                    print("[\(Date())] Error: Default input source ('\(defaultInputSourceID)') not found.")
                    return
                }
                
                selectInputSource(sourceToSwitchTo)
                hebrewTimer.stopHebrewSession()
            }
        } else {
            print("[\(Date())] Active: \(currentName). Hebrew session not initialized.")
        }
    } else if currentID != defaultInputSourceID {
        // Different non-default language
        print("[\(Date())] Active: \(currentName). Monitoring only Hebrew for auto-switch.")
    } else {
        // Default language (English)
        print("[\(Date())] Active: \(currentName). Status OK.")
    }
    
    // Flush output to ensure it appears immediately
    fflush(stdout)
    }
}

// MARK: - Command Line Argument Parsing

func parseCommandLineArguments() -> TimeInterval {
    let arguments = CommandLine.arguments
    
    // Check for help flag
    if arguments.contains("-h") || arguments.contains("--help") {
        print("KeyboardGuard - Automatic Hebrew to English keyboard layout switcher")
        print("")
        print("Usage: KeyboardGuard [timeout_seconds]")
        print("")
        print("Arguments:")
        print("  timeout_seconds    Number of seconds to wait before switching (default: \(defaultIdleTimeout))")
        print("")
        print("Options:")
        print("  -h, --help        Show this help message")
        print("")
        print("Examples:")
        print("  KeyboardGuard           # Use default timeout (\(defaultIdleTimeout) seconds)")
        print("  KeyboardGuard 30        # Wait 30 seconds before switching")
        print("  KeyboardGuard 5         # Wait 5 seconds before switching")
        exit(0)
    }
    
    // Parse timeout argument
    if arguments.count > 1 {
        if let timeout = TimeInterval(arguments[1]), timeout > 0 {
            return timeout
        } else {
            print("Error: Invalid timeout value '\(arguments[1])'. Must be a positive number.")
            print("Using default timeout of \(defaultIdleTimeout) seconds.")
            return defaultIdleTimeout
        }
    }
    
    return defaultIdleTimeout
}

// MARK: - Program Entry

let idleTimeout = parseCommandLineArguments()
let keyboardGuard = KeyboardGuard(idleTimeout: idleTimeout)

if keyboardGuard.defaultSource == nil {
    print("FATAL ERROR: The default input source ID '\(defaultInputSourceID)' could not be found. Please ensure it is enabled in Keyboard Settings > Input Sources.")
    exit(1)
} else {
    print("Keyboard Guard is starting.")
    print("Targeted language for switch: \(targetInputSourceID)")
    print("Default language: \(defaultInputSourceID)")
    print("Idle timeout set to: \(idleTimeout) seconds.")
    print("Check interval: \(checkInterval) seconds.")
    print("Monitoring...")
    fflush(stdout)
    
    // Test the function immediately
    print("Running initial check...")
    keyboardGuard.runLanguageCheck()

    // Set up a repeating timer on the main run loop.
    Timer.scheduledTimer(timeInterval: checkInterval, target: keyboardGuard, selector: #selector(KeyboardGuard.runLanguageCheck), userInfo: nil, repeats: true)

    // Keep the process alive indefinitely to allow the timer to fire.
    RunLoop.current.run()
}