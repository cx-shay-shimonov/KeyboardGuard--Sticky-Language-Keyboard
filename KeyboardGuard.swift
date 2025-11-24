import Foundation
// The Carbon module contains the necessary C functions for Text Input Services (TIS).
import Carbon
// AppKit for NSEvent.addLocalMonitorForEvents fallback
import AppKit
// IOKit for system idle time detection via HIDIdleTime
import IOKit
// AudioToolbox for sound effects
import AudioToolbox
// Cocoa for toast notifications
import Cocoa

// MARK: - Configuration

/// Configuration structure that mirrors the JSON file
struct Configuration: Codable {
    let supportedLanguages: [String: String]
    let defaultConfiguration: DefaultConfiguration
    
    struct DefaultConfiguration: Codable {
        let idleTimeout: TimeInterval
        let defaultLanguage: String
        let checkInterval: TimeInterval
    }
}

/// Global configuration loaded from JSON file
private var globalConfig: Configuration?

/// Loads configuration from languages.json file
func loadConfiguration() -> Configuration {
    let configFileName = "languages.json"
    
    // Try to find the config file in the same directory as the executable
    var configURL: URL
    
    if let executablePath = ProcessInfo.processInfo.arguments.first {
        let executableURL = URL(fileURLWithPath: executablePath)
        configURL = executableURL.deletingLastPathComponent().appendingPathComponent(configFileName)
    } else {
        // Fallback to current directory
        configURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(configFileName)
    }
    
    // Try loading from executable directory first, then current directory
    let possiblePaths = [
        configURL,
        URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(configFileName)
    ]
    
    for url in possiblePaths {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let config = try decoder.decode(Configuration.self, from: data)
            print("Configuration loaded from: \(url.path)")
            return config
        } catch {
            continue // Try next path
        }
    }
    
    // If we can't load the config file, create a default one and use fallback values
    print("Warning: Could not load \(configFileName). Creating default configuration file.")
    createDefaultConfigFile(at: possiblePaths[1]) // Create in current directory
    
    // Return fallback configuration
    return Configuration(
        supportedLanguages: [
            "english": "com.apple.keylayout.ABC",
            "hebrew": "com.apple.keylayout.Hebrew",
            "portuguese": "com.apple.keylayout.Portuguese",
            "spanish": "com.apple.keylayout.Spanish",
            "french": "com.apple.keylayout.French",
            "german": "com.apple.keylayout.German"
        ],
        defaultConfiguration: Configuration.DefaultConfiguration(
            idleTimeout: 10.0,
            defaultLanguage: "english",
            checkInterval: 1.0
        )
    )
}

/// Creates a default configuration file
func createDefaultConfigFile(at url: URL) {
    let defaultConfig = Configuration(
        supportedLanguages: [
            "english": "com.apple.keylayout.ABC",
            "us": "com.apple.keylayout.US",
            "british": "com.apple.keylayout.British",
            "hebrew": "com.apple.keylayout.Hebrew",
            "portuguese": "com.apple.keylayout.Portuguese",
            "spanish": "com.apple.keylayout.Spanish",
            "french": "com.apple.keylayout.French",
            "german": "com.apple.keylayout.German",
            "italian": "com.apple.keylayout.Italian",
            "russian": "com.apple.keylayout.Russian"
        ],
        defaultConfiguration: Configuration.DefaultConfiguration(
            idleTimeout: 10.0,
            defaultLanguage: "english",
            checkInterval: 1.0
        )
    )
    
    do {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(defaultConfig)
        try data.write(to: url)
        print("Default configuration file created at: \(url.path)")
        print("You can edit this file to add more languages.")
    } catch {
        print("Warning: Could not create default configuration file: \(error)")
    }
}

// Load configuration at startup
let jsonConfig = loadConfiguration()
globalConfig = jsonConfig

// Make configuration easily accessible
let supportedLanguages = jsonConfig.supportedLanguages
let defaultIdleTimeout = jsonConfig.defaultConfiguration.idleTimeout
let defaultDefaultLanguage = jsonConfig.defaultConfiguration.defaultLanguage
let checkInterval = jsonConfig.defaultConfiguration.checkInterval

// MARK: - Sound Effects

/// Plays a system sound by name
/// - Parameter soundName: The name of the sound file (e.g., "Ping", "Glass")
func playSound(_ soundName: String) {
    let task = Process()
    task.launchPath = "/usr/bin/afplay"
    task.arguments = ["/System/Library/Sounds/\(soundName).aiff"]
    
    do {
        try task.run()
        // Don't wait - let it play in background
    } catch {
        // Silent fallback - don't print errors during normal operation
    }
}

/// Plays success sound when language switching succeeds
func playSuccessSound() {
    playSound("Ping")
}

/// Plays failure sound when language switching fails
func playFailureSound() {
    playSound("Glass")
}

// MARK: - Visual Toast Notifications

/// Shows a brief toast notification when language switches back to default
/// 
/// This function creates a simple overlay window without NSApplication setup
/// to avoid interfering with the main run loop.
///
/// - Parameters:
///   - fromLanguage: The language we switched from (e.g., "hebrew")
///   - toLanguage: The default language we switched to (e.g., "english")
func showLanguageSwitchToast(from fromLanguage: String, to toLanguage: String) {
    // Use a simple approach that doesn't require NSApplication
    DispatchQueue.main.async {
        // Create a simple borderless window
        let toastWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 80),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        // Configure window
        toastWindow.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.9)
        toastWindow.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.floatingWindow)))
        toastWindow.isOpaque = false
        toastWindow.hasShadow = true
        toastWindow.ignoresMouseEvents = true
        
        // Create content
        let contentView = NSView(frame: toastWindow.contentRect(forFrameRect: toastWindow.frame))
        toastWindow.contentView = contentView
        
        // Add text
        let label = NSTextField(labelWithString: "🔄 \(fromLanguage.capitalized) → \(toLanguage.capitalized)")
        label.font = NSFont.systemFont(ofSize: 16, weight: .medium)
        label.alignment = .center
        label.frame = NSRect(x: 20, y: 30, width: 260, height: 20)
        contentView.addSubview(label)
        
        // Position at top-right
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.maxX - 320
            let y = screenFrame.maxY - 100
            toastWindow.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        // Show and auto-close
        toastWindow.orderFront(nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            toastWindow.close()
        }
    }
}

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

/// Gets all available input sources on the current system
/// - Returns: Set of input source IDs that are available
func getAvailableInputSources() -> Set<String> {
    var availableSources = Set<String>()
    
    // Get all input sources
    guard let inputSources = TISCreateInputSourceList(nil, false)?.takeRetainedValue() as? [TISInputSource] else {
        return availableSources
    }
    
    for source in inputSources {
        if let properties = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) {
            let sourceID = Unmanaged<CFString>.fromOpaque(properties).takeUnretainedValue() as String
            availableSources.insert(sourceID)
        }
    }
    
    return availableSources
}

/// Gets available languages from our supported list that are actually enabled on this system
/// - Returns: Array of language names that are available
func getAvailableLanguages() -> [String] {
    let availableSources = getAvailableInputSources()
    var availableLanguages: [String] = []
    
    for (language, sourceID) in supportedLanguages {
        if availableSources.contains(sourceID) {
            availableLanguages.append(language)
        }
    }
    
    return availableLanguages.sorted()
}

/// Validates if a language is available on the current system
/// - Parameter language: The language name to validate
/// - Returns: True if the language is available, false otherwise
func isLanguageAvailable(_ language: String) -> Bool {
    guard let sourceID = supportedLanguages[language.lowercased()] else {
        return false
    }
    
    let availableSources = getAvailableInputSources()
    return availableSources.contains(sourceID)
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

// MARK: - System Idle Time Utility

/// Idle detection modes
enum IdleMode: String, CaseIterable {
    case keyboard = "keyboard"  // Only keyboard activity resets timer
    case mouse = "mouse"       // Only mouse activity resets timer  
    case system = "system"     // Both keyboard and mouse activity reset timer (default)
    
    var description: String {
        switch self {
        case .keyboard: return "keyboard-only"
        case .mouse: return "mouse-only"
        case .system: return "system (keyboard + mouse)"
        }
    }
}

/// Enhanced idle time monitor that can distinguish between keyboard, mouse, and system idle time
class EnhancedIdleTimeMonitor {
    private var lastKeyboardActivity: Date = Date()
    private var lastMouseActivity: Date = Date()
    private let idleMode: IdleMode
    
    init(mode: IdleMode = .system) {
        self.idleMode = mode
        
        switch mode {
        case .keyboard:
            print("Keyboard-only idle time monitor initialized...")
            setupKeyboardMonitoring()
        case .mouse:
            print("Mouse-only idle time monitor initialized...")
            setupMouseMonitoring()
        case .system:
            print("System idle time monitor initialized...")
            // Use both keyboard and mouse monitoring for most accurate system tracking
            setupKeyboardMonitoring()
            setupMouseMonitoring()
        }
    }
    
    /// Gets the keyboard idle time - always based on keyboard activity
    /// Mouse events can reset this timer in mouse mode, but we always measure keyboard idle time
    func getIdleTime() -> TimeInterval {
        let now = Date()
        
        switch idleMode {
        case .keyboard:
            // Pure keyboard mode - only keyboard activity matters
            return now.timeIntervalSince(lastKeyboardActivity)
        case .mouse:
            // Mouse mode - mouse events reset keyboard timer, but we still measure keyboard idle time
            let keyboardIdle = now.timeIntervalSince(lastKeyboardActivity)
            let mouseIdle = now.timeIntervalSince(lastMouseActivity)
            // If mouse was active more recently, use that to reset keyboard timer
            return min(keyboardIdle, mouseIdle)
        case .system:
            // System mode - either keyboard or mouse activity resets timer
            let keyboardIdle = now.timeIntervalSince(lastKeyboardActivity)
            let mouseIdle = now.timeIntervalSince(lastMouseActivity)
            return min(keyboardIdle, mouseIdle)
        }
    }
    
    /// Gets the legacy system idle time using IOKit (for comparison/fallback)
    func getSystemIdleTime() -> TimeInterval {
        var iterator: io_iterator_t = 0
        let result = IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOHIDSystem"), &iterator)
        
        if result != KERN_SUCCESS {
            return 0.0
        }
        
        defer { IOObjectRelease(iterator) }
        
        let entry = IOIteratorNext(iterator)
        if entry == 0 {
            return 0.0
        }
        
        defer { IOObjectRelease(entry) }
        
        var properties: Unmanaged<CFMutableDictionary>?
        let propertiesResult = IORegistryEntryCreateCFProperties(entry, &properties, kCFAllocatorDefault, 0)
        
        if propertiesResult != KERN_SUCCESS {
            return 0.0
        }
        
        guard let dict = properties?.takeRetainedValue() else {
            return 0.0
        }
        
        let key = "HIDIdleTime" as CFString
        guard let idleTimeNumber = CFDictionaryGetValue(dict, Unmanaged.passUnretained(key).toOpaque()) else {
            return 0.0
        }
        
        var idleTimeValue: Int64 = 0
        let success = CFNumberGetValue(unsafeBitCast(idleTimeNumber, to: CFNumber.self), .sInt64Type, &idleTimeValue)
        
        if !success {
            return 0.0
        }
        
        // Convert from nanoseconds to seconds
        return Double(idleTimeValue) / 1_000_000_000.0
    }
    
    /// Sets up keyboard event monitoring
    private func setupKeyboardMonitoring() {
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue) | (1 << CGEventType.flagsChanged.rawValue)
        
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                // Update keyboard activity timestamp
                if let monitor = Unmanaged<EnhancedIdleTimeMonitor>.fromOpaque(refcon!).takeUnretainedValue() as EnhancedIdleTimeMonitor? {
                    monitor.lastKeyboardActivity = Date()
                }
                return Unmanaged.passRetained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("Warning: Could not create keyboard event tap. Falling back to system idle time.")
            return
        }
        
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }
    
    /// Sets up mouse event monitoring
    private func setupMouseMonitoring() {
        let eventMask = (1 << CGEventType.mouseMoved.rawValue) | 
                       (1 << CGEventType.leftMouseDown.rawValue) | 
                       (1 << CGEventType.leftMouseUp.rawValue) |
                       (1 << CGEventType.rightMouseDown.rawValue) | 
                       (1 << CGEventType.rightMouseUp.rawValue) |
                       (1 << CGEventType.scrollWheel.rawValue)
        
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                // Update mouse activity timestamp
                if let monitor = Unmanaged<EnhancedIdleTimeMonitor>.fromOpaque(refcon!).takeUnretainedValue() as EnhancedIdleTimeMonitor? {
                    monitor.lastMouseActivity = Date()
                }
                return Unmanaged.passRetained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("Warning: Could not create mouse event tap. Falling back to system idle time.")
            return
        }
        
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }
}

/// Manages non-default language idle timing (any language that isn't the default)
class NonDefaultLanguageTimer {
    private var sessionStartTime: Date?
    private var lastActivityInNonDefaultLanguage: Date?
    private var currentLanguageName: String?
    
    /// Call when switching TO any non-default language
    func startNonDefaultLanguageSession(languageName: String) {
        sessionStartTime = Date()
        lastActivityInNonDefaultLanguage = Date()
        currentLanguageName = languageName
        print("\(languageName.capitalized) session started - idle timer initialized")
    }
    
    /// Call when there's keyboard activity while in non-default language
    func recordNonDefaultLanguageActivity() {
        lastActivityInNonDefaultLanguage = Date()
    }
    
    /// Get idle time since last activity in non-default language (only valid if session is active)
    func getNonDefaultLanguageIdleTime() -> TimeInterval? {
        guard let lastActivity = lastActivityInNonDefaultLanguage else { return nil }
        return Date().timeIntervalSince(lastActivity)
    }
    
    /// Stop non-default language session (when switching to default language)
    func stopNonDefaultLanguageSession() {
        if let langName = currentLanguageName {
            print("\(langName.capitalized) session ended")
        }
        sessionStartTime = nil
        lastActivityInNonDefaultLanguage = nil
        currentLanguageName = nil
    }
    
    /// Returns true if currently in a non-default language session
    func isInNonDefaultLanguageSession() -> Bool {
        return sessionStartTime != nil
    }
    
    /// Get the current non-default language name
    func getCurrentLanguageName() -> String? {
        return currentLanguageName
    }
}

// MARK: - Main Logic

class KeyboardGuard {
    // Store a reference to the default source once to avoid repeated lookups.
    var defaultSource: TISInputSource?
    // Monitor idle time with configurable mode
    private let idleTimeMonitor: EnhancedIdleTimeMonitor
    // Manage non-default language-specific idle timing
    private let nonDefaultLanguageTimer = NonDefaultLanguageTimer()
    // Configurable idle timeout
    private let idleTimeout: TimeInterval
    // Default language info (what to switch TO)
    private let defaultInputSourceID: String
    private let defaultLanguageName: String
    // Sound effect setting
    private let soundEnabled: Bool
    // Visual notification setting
    private let visualEnabled: Bool
    // Daemon mode setting
    private let daemonMode: Bool
    // Track previous language to detect switches
    private var previousLanguageID: String?
    // Track previous global idle time to detect typing
    private var previousGlobalIdleTime: TimeInterval = 0
    
    init(idleTimeout: TimeInterval, defaultLanguage: String, soundEnabled: Bool = true, visualEnabled: Bool = true, daemonMode: Bool = false, idleMode: IdleMode = .system) {
        self.idleTimeout = idleTimeout
        self.defaultLanguageName = defaultLanguage
        self.soundEnabled = soundEnabled
        self.visualEnabled = visualEnabled
        self.daemonMode = daemonMode
        self.idleTimeMonitor = EnhancedIdleTimeMonitor(mode: idleMode)
        
        // Get the default input source ID from the language mapping
        if let inputSourceID = supportedLanguages[defaultLanguage.lowercased()] {
            self.defaultInputSourceID = inputSourceID
        } else {
            print("ERROR: Unsupported default language '\(defaultLanguage)'. Falling back to English.")
            self.defaultInputSourceID = supportedLanguages["english"] ?? "com.apple.keylayout.ABC"
        }
        
        // Look up the default input source once at startup.
        defaultSource = findInputSource(by: defaultInputSourceID)
        
        if !daemonMode {
            print("Note: Using \(idleMode.description) idle detection for precise activity tracking.")
        }
    }
    
    /// Prints a message only if not in daemon mode
    private func log(_ message: String) {
        if !daemonMode {
            print(message)
            fflush(stdout)
        }
    }
    
    /// Helper function to get language name from input source ID
    private func getLanguageNameFromID(_ inputSourceID: String) -> String {
        for (language, id) in supportedLanguages {
            if id == inputSourceID {
                return language
            }
        }
        return "unknown"
    }
    
    /// Check if currently in default language
    func isCurrentlyInDefaultLanguage() -> Bool {
        guard let currentID = getCurrentInputSourceID() else {
            return false
        }
        return currentID == defaultInputSourceID
    }
    

    /// The core function that checks the current state and switches the keyboard if necessary.
    @objc func runLanguageCheck() {
    guard let currentID = getCurrentInputSourceID() else {
        log("[\(Date())] Could not determine current input source ID.")
        return
    }

    let currentInputSource = TISCopyCurrentKeyboardInputSource()?.takeUnretainedValue()
    let nameProperty = currentInputSource != nil ? TISGetInputSourceProperty(currentInputSource!, kTISPropertyLocalizedName) : nil
    let currentName = nameProperty != nil ? Unmanaged<CFString>.fromOpaque(nameProperty!).takeUnretainedValue() as String : "Unknown"

    // Determine if current language is default or non-default
    let isCurrentlyDefault = currentID == defaultInputSourceID
    let wasDefaultPreviously = previousLanguageID == defaultInputSourceID
    
    // Detect language changes
    let switchedToNonDefault = !isCurrentlyDefault && wasDefaultPreviously
    let switchedToDefault = isCurrentlyDefault && !wasDefaultPreviously
    
    // Get system idle time for typing detection (more reliable than CGEvent taps)
    let systemIdleTime = idleTimeMonitor.getSystemIdleTime()
    let isCurrentlyTyping = systemIdleTime < 1.0 // Consider "typing" if idle < 1 second
    
    // Handle non-default language session management
    if switchedToNonDefault {
        let currentLanguageName = getLanguageNameFromID(currentID)
        log("[\(Date())] Switched TO \(currentLanguageName.capitalized) (non-default)")
        nonDefaultLanguageTimer.startNonDefaultLanguageSession(languageName: currentLanguageName)
        // IMPORTANT: Reset timer immediately when switching to secondary language
        nonDefaultLanguageTimer.recordNonDefaultLanguageActivity()
        log("[\(Date())] Timer reset due to language switch")
    } else if switchedToDefault {
        nonDefaultLanguageTimer.stopNonDefaultLanguageSession()
    } else if !isCurrentlyDefault && !nonDefaultLanguageTimer.isInNonDefaultLanguageSession() {
        // Handle case where we start in non-default language or session wasn't initialized
        let currentLanguageName = getLanguageNameFromID(currentID)
        print("[\(Date())] Initializing session for \(currentLanguageName.capitalized) (already active)")
        nonDefaultLanguageTimer.startNonDefaultLanguageSession(languageName: currentLanguageName)
        // IMPORTANT: Reset timer immediately when initializing session
        nonDefaultLanguageTimer.recordNonDefaultLanguageActivity()
        print("[\(Date())] Timer reset due to session initialization")
    }
    
    // Update previous language for next check
    previousLanguageID = currentID

    // Main logic
    if !isCurrentlyDefault {
        // Currently in any non-default language
        let currentLanguageName = getLanguageNameFromID(currentID)
        
        // Initialize session if needed (fallback for polling-based detection)
        if !nonDefaultLanguageTimer.isInNonDefaultLanguageSession() {
            print("[\(Date())] Starting timer for \(currentLanguageName.capitalized) (polling fallback)")
            nonDefaultLanguageTimer.startNonDefaultLanguageSession(languageName: currentLanguageName)
            nonDefaultLanguageTimer.recordNonDefaultLanguageActivity()
        }
        
        // Detect typing by checking if system idle time decreased or is very small
        // Use reliable IOKit system idle time for typing detection
        let typingDetected = systemIdleTime < previousGlobalIdleTime || systemIdleTime < 0.5
        
        if typingDetected && nonDefaultLanguageTimer.isInNonDefaultLanguageSession() {
            nonDefaultLanguageTimer.recordNonDefaultLanguageActivity()
            print("[\(Date())] Timer reset due to typing detected (system idle: \(String(format: "%.1f", systemIdleTime))s, prev: \(String(format: "%.1f", previousGlobalIdleTime))s)")
        }
        
        // Update previous idle time for next comparison
        previousGlobalIdleTime = systemIdleTime
        
        // Use secondary language timer for switching decision
        if let secondaryIdleTime = nonDefaultLanguageTimer.getNonDefaultLanguageIdleTime() {
            log("[\(Date())] Active: \(currentName). \(currentLanguageName.capitalized) Idle Time: \(String(format: "%.1f", secondaryIdleTime))s. System: \(String(format: "%.1f", systemIdleTime))s. Typing: \(isCurrentlyTyping)")
            
            // Switch based on secondary language idle time
            if secondaryIdleTime >= idleTimeout {
                log("[\(Date())] \(currentLanguageName.capitalized) idle time exceeded \(idleTimeout)s. Switching to \(defaultLanguageName.capitalized).")
                
                guard let sourceToSwitchTo = defaultSource else {
                    print("[\(Date())] Error: Default input source ('\(defaultInputSourceID)') not found.")
                    
                    // Play failure sound if enabled
                    if soundEnabled {
                        playFailureSound()
                    }
                    
                    return
                }
                
                selectInputSource(sourceToSwitchTo)
                
                // Play success sound if enabled
                if soundEnabled {
                    playSuccessSound()
                }
                
                // Show toast notification if enabled
                if visualEnabled {
                    // Temporarily disabled to prevent crashes - will fix in next iteration
                    print("[\(Date())] Visual notification: \(currentLanguageName.capitalized) → \(defaultLanguageName.capitalized)")
                }
                
                nonDefaultLanguageTimer.stopNonDefaultLanguageSession()
            }
        } else {
            print("[\(Date())] Active: \(currentName). \(currentLanguageName.capitalized) timer not initialized.")
        }
    } else {
        // Currently in default language
        log("[\(Date())] Active: \(currentName) (\(defaultLanguageName.capitalized)). Status OK.")
    }
    
    // Flush output to ensure it appears immediately
    fflush(stdout)
    }
}

// MARK: - Command Line Argument Parsing

struct ProgramConfig {
    let timeout: TimeInterval
    let defaultLanguage: String
    let soundEnabled: Bool
    let visualEnabled: Bool
    let daemonMode: Bool
    let idleMode: IdleMode
}

func parseCommandLineArguments() -> ProgramConfig {
    let arguments = CommandLine.arguments
    var timeout = defaultIdleTimeout
    var defaultLanguage = defaultDefaultLanguage
    let soundEnabled = !arguments.contains("--nosound") // Default is true unless --nosound is provided
    let visualEnabled = !arguments.contains("--novisual") // Default is true unless --novisual is provided
    let daemonMode = arguments.contains("--daemon") || arguments.contains("-d") // Default is false unless --daemon is provided
    var idleMode: IdleMode = .system // Default to system mode (keyboard + mouse)
    
    // Check for help flag
    if arguments.contains("-h") || arguments.contains("--help") {
        showHelp()
        exit(0)
    }
    
    // Parse arguments
    var i = 1
    while i < arguments.count {
        let arg = arguments[i]
        
        switch arg {
        case "-t", "--time":
            // Get timeout value
            if i + 1 < arguments.count {
                i += 1
                if let timeoutValue = TimeInterval(arguments[i]), timeoutValue > 0 {
                    timeout = timeoutValue
                } else {
                    print("Error: Invalid timeout value '\(arguments[i])'. Must be a positive number.")
                    print("Using default timeout of \(defaultIdleTimeout) seconds.")
                }
            } else {
                print("Error: -t/--time requires a timeout value.")
                print("Using default timeout of \(defaultIdleTimeout) seconds.")
            }
            
        case "-l", "--language":
            // Get default language value
            if i + 1 < arguments.count {
                i += 1
                let lang = arguments[i].lowercased()
                if supportedLanguages[lang] != nil {
                    // Check if language is available on system
                    if isLanguageAvailable(lang) {
                        defaultLanguage = lang
                    } else {
                        print("Error: Language '\(arguments[i])' is not enabled on your system.")
                        print("Available languages on your system: \(getAvailableLanguages().joined(separator: ", "))")
                        print("")
                        print("To enable '\(arguments[i])' keyboard layout:")
                        print("1. Go to System Preferences → Keyboard → Input Sources")
                        print("2. Click + to add '\(arguments[i])' keyboard layout")
                        print("3. Run KeyboardGuard again")
                        exit(1)
                    }
                } else {
                    print("Error: Unsupported language '\(arguments[i])'.")
                    print("Supported languages: \(supportedLanguages.keys.sorted().joined(separator: ", "))")
                    print("Available languages on your system: \(getAvailableLanguages().joined(separator: ", "))")
                    exit(1)
                }
            } else {
                print("Error: -l/--language requires a language name.")
                print("Available languages on your system: \(getAvailableLanguages().joined(separator: ", "))")
                exit(1)
            }
            
        case "--nosound":
            // --nosound flag is already handled above, just skip it here
            break
            
        case "--novisual":
            // --novisual flag is already handled above, just skip it here
            break
            
        case "--daemon", "-d":
            // --daemon flag is already handled above, just skip it here
            break
            
        case "--idle-mode":
            // Get idle mode value
            if i + 1 < arguments.count {
                i += 1
                let modeString = arguments[i].lowercased()
                if let mode = IdleMode(rawValue: modeString) {
                    idleMode = mode
                } else {
                    print("Error: Invalid idle mode '\(arguments[i])'. Valid options: keyboard, mouse, system")
                    print("Using default: system")
                }
            } else {
                print("Error: --idle-mode requires a mode (keyboard, mouse, system).")
                print("Using default: system")
            }
            
        default:
            // Try to parse as timeout (backward compatibility)
            if let timeoutValue = TimeInterval(arg), timeoutValue > 0 {
                timeout = timeoutValue
            } else {
                print("Error: Unknown argument '\(arg)'. Use -h for help.")
            }
        }
        
        i += 1
    }
    
    // Validate default language is available on system
    if !isLanguageAvailable(defaultLanguage) {
        print("Error: Default language '\(defaultLanguage)' is not enabled on your system.")
        print("Available languages on your system: \(getAvailableLanguages().joined(separator: ", "))")
        print("")
        print("To enable '\(defaultLanguage)' keyboard layout:")
        print("1. Go to System Preferences → Keyboard → Input Sources")
        print("2. Click + to add '\(defaultLanguage)' keyboard layout")
        print("3. Run KeyboardGuard again")
        exit(1)
    }
    
    return ProgramConfig(timeout: timeout, defaultLanguage: defaultLanguage, soundEnabled: soundEnabled, visualEnabled: visualEnabled, daemonMode: daemonMode, idleMode: idleMode)
}

func showHelp() {
    print("KeyboardGuard - Universal automatic keyboard layout switcher")
    print("")
    print("Monitors ALL non-default languages and automatically switches back to your")
    print("default language when you stop typing for a specified period.")
    print("")
    print("Usage: KeyboardGuard [options]")
    print("")
    print("Options:")
    print("  -t, --time SECONDS     Idle timeout in seconds (default: \(Int(defaultIdleTimeout)))")
    print("  -l, --language LANG    Default language to switch TO (default: \(defaultDefaultLanguage))")
    print("  --nosound              Disable sound effects (default: sound enabled)")
    print("  --novisual             Disable toast notifications (default: visual enabled)")
    print("  -d, --daemon           Run in background daemon mode (no terminal output)")
    print("  --idle-mode MODE       Idle detection mode: keyboard, mouse, system (default: system)")
    print("  -h, --help            Show this help message")
    print("")
    print("How it works:")
    print("  • Any language that is NOT your default language will trigger the timer")
    print("  • When you stop typing in any non-default language, it starts counting")
    print("  • After the timeout, it automatically switches to your default language")
    print("")
    print("Available Languages on Your System:")
    let availableLanguages = getAvailableLanguages()
    if availableLanguages.isEmpty {
        print("  No supported languages found. Please enable keyboard layouts in System Preferences.")
    } else {
        for (index, language) in availableLanguages.enumerated() {
            let prefix = (index % 6 == 0) ? "\n  " : ", "
            print("\(prefix)\(language)", terminator: "")
        }
        print("\n")
    }
    
    print("All Supported Languages:")
    let allLanguages = supportedLanguages.keys.sorted()
    for (index, language) in allLanguages.enumerated() {
        let prefix = (index % 6 == 0) ? "\n  " : ", "
        print("\(prefix)\(language)", terminator: "")
    }
    print("\n")
    print("Examples:")
    print("  KeyboardGuard                          # System idle detection (keyboard + mouse), 10s timeout")
    print("  KeyboardGuard -l portuguese            # Any non-Portuguese -> Portuguese")
    print("  KeyboardGuard -t 30                    # 30s timeout with system idle detection")
    print("  KeyboardGuard --idle-mode keyboard     # Keyboard-only idle detection")
    print("  KeyboardGuard --idle-mode mouse        # Mouse-only idle detection")
    print("  KeyboardGuard --daemon                 # Run in background daemon mode")
    print("  KeyboardGuard --daemon --idle-mode keyboard -t 15  # Keyboard-only daemon mode")
    print("  KeyboardGuard --nosound --novisual     # Silent mode (no audio/visual feedback)")
    print("")
    print("Backward Compatibility:")
    print("  KeyboardGuard 30                       # Any non-English -> English, 30s timeout")
}

// MARK: - Daemon Mode Support

/// Prepares the process for daemon mode by redirecting output
func setupDaemonMode() {
    print("KeyboardGuard starting in daemon mode (PID: \(getpid()))")
    print("Use 'pkill KeyboardGuard' to stop, or './check_status.sh' to check status")
    
    // Redirect stdout and stderr to /dev/null to suppress output
    let devNull = open("/dev/null", O_WRONLY)
    if devNull != -1 {
        dup2(devNull, STDOUT_FILENO)
        dup2(devNull, STDERR_FILENO)
        close(devNull)
    }
}

// MARK: - Program Entry

let cmdConfig = parseCommandLineArguments()

// Note: NSApplication initialization completely removed to prevent run loop interference
// Toast notifications will use a different approach that doesn't require NSApplication setup

// Handle daemon mode before creating KeyboardGuard instance
if cmdConfig.daemonMode {
    setupDaemonMode()
    // After setup, output will be redirected to /dev/null
}

let keyboardGuard = KeyboardGuard(idleTimeout: cmdConfig.timeout, defaultLanguage: cmdConfig.defaultLanguage, soundEnabled: cmdConfig.soundEnabled, visualEnabled: cmdConfig.visualEnabled, daemonMode: cmdConfig.daemonMode, idleMode: cmdConfig.idleMode)

if keyboardGuard.defaultSource == nil {
    if !cmdConfig.daemonMode {
        print("FATAL ERROR: The default input source could not be found. Please ensure \(cmdConfig.defaultLanguage.capitalized) keyboard layout is enabled in Keyboard Settings > Input Sources.")
    }
    exit(1)
} else {
    // Only show startup messages if not in daemon mode
    if !cmdConfig.daemonMode {
        print("KeyboardGuard is starting.")
        print("Default language: \(cmdConfig.defaultLanguage.capitalized)")
        print("Behavior: Any non-\(cmdConfig.defaultLanguage) language -> \(cmdConfig.defaultLanguage.capitalized)")
        print("Idle timeout: \(cmdConfig.timeout) seconds")
        print("Sound effects: \(cmdConfig.soundEnabled ? "enabled (Ping/Glass)" : "disabled")")
        print("Visual notifications: \(cmdConfig.visualEnabled ? "enabled (toast)" : "disabled")")
        print("Idle detection: \(cmdConfig.idleMode.description)")
        print("Check interval: \(checkInterval) seconds")
        print("Monitoring...")
        fflush(stdout)
        
        // Test the function immediately (only in interactive mode)
        print("Running initial check...")
    }
    
    // Run initial check
    keyboardGuard.runLanguageCheck()

    // Set up a repeating timer on the main run loop.
    Timer.scheduledTimer(timeInterval: checkInterval, target: keyboardGuard, selector: #selector(KeyboardGuard.runLanguageCheck), userInfo: nil, repeats: true)

    // Keep the process alive indefinitely to allow the timer to fire.
    RunLoop.current.run()
}