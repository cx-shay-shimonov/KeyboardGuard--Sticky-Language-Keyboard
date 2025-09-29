import Foundation
// The Carbon module contains the necessary C functions for Text Input Services (TIS).
import Carbon
// AppKit for keyboard event monitoring
import AppKit

// MARK: - Configuration

// Language mapping for common languages to their macOS Input Source IDs
let supportedLanguages: [String: String] = [
    // English variants
    "english": "com.apple.keylayout.ABC",
    "us": "com.apple.keylayout.US",
    "british": "com.apple.keylayout.British",
    "australian": "com.apple.keylayout.Australian",
    
    // European languages
    "hebrew": "com.apple.keylayout.Hebrew",
    "portuguese": "com.apple.keylayout.Portuguese",
    "spanish": "com.apple.keylayout.Spanish",
    "french": "com.apple.keylayout.French",
    "german": "com.apple.keylayout.German",
    "italian": "com.apple.keylayout.Italian",
    "russian": "com.apple.keylayout.Russian",
    "dutch": "com.apple.keylayout.Dutch",
    "swedish": "com.apple.keylayout.Swedish",
    "norwegian": "com.apple.keylayout.Norwegian",
    "danish": "com.apple.keylayout.Danish",
    "finnish": "com.apple.keylayout.Finnish",
    "polish": "com.apple.keylayout.Polish",
    "czech": "com.apple.keylayout.Czech",
    "hungarian": "com.apple.keylayout.Hungarian",
    "greek": "com.apple.keylayout.Greek",
    "turkish": "com.apple.keylayout.Turkish",
    
    // Asian languages
    "arabic": "com.apple.keylayout.Arabic",
    "chinese": "com.apple.keylayout.Chinese-Traditional",
    "simplified-chinese": "com.apple.keylayout.Chinese-Simplified",
    "japanese": "com.apple.keylayout.Japanese",
    "korean": "com.apple.keylayout.Korean",
    "thai": "com.apple.keylayout.Thai",
    "vietnamese": "com.apple.keylayout.Vietnamese",
    
    // Other common languages
    "hindi": "com.apple.keylayout.Devanagari",
    "urdu": "com.apple.keylayout.Urdu",
    "persian": "com.apple.keylayout.Persian",
    "bulgarian": "com.apple.keylayout.Bulgarian",
    "croatian": "com.apple.keylayout.Croatian",
    "romanian": "com.apple.keylayout.Romanian",
    "ukrainian": "com.apple.keylayout.Ukrainian"
]

// Default configuration
let defaultIdleTimeout: TimeInterval = 10.0 // Default: 10 seconds
let defaultDefaultLanguage: String = "english" // Default language to switch TO

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
    // Monitor keyboard activity globally
    private let keyboardMonitor = KeyboardActivityMonitor()
    // Manage non-default language-specific idle timing
    private let nonDefaultLanguageTimer = NonDefaultLanguageTimer()
    // Configurable idle timeout
    private let idleTimeout: TimeInterval
    // Default language info (what to switch TO)
    private let defaultInputSourceID: String
    private let defaultLanguageName: String
    // Track previous language to detect switches
    private var previousLanguageID: String?
    
    init(idleTimeout: TimeInterval, defaultLanguage: String) {
        self.idleTimeout = idleTimeout
        self.defaultLanguageName = defaultLanguage
        
        // Get the default input source ID from the language mapping
        if let inputSourceID = supportedLanguages[defaultLanguage.lowercased()] {
            self.defaultInputSourceID = inputSourceID
        } else {
            print("ERROR: Unsupported default language '\(defaultLanguage)'. Falling back to English.")
            self.defaultInputSourceID = supportedLanguages["english"]!
        }
        
        // Look up the default input source once at startup.
        defaultSource = findInputSource(by: defaultInputSourceID)
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

    /// The core function that checks the current state and switches the keyboard if necessary.
    @objc func runLanguageCheck() {
    guard let currentID = getCurrentInputSourceID() else {
        print("[\(Date())] Could not determine current input source ID.")
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
    
    // Get current keyboard activity status
    let timeSinceLastKeyboard = keyboardMonitor.getTimeSinceLastKeyboardEvent()
    let isCurrentlyTyping = timeSinceLastKeyboard < 1.0 // Consider "typing" if keystroke within 1 second
    
    // Handle non-default language session management
    if switchedToNonDefault {
        let currentLanguageName = getLanguageNameFromID(currentID)
        print("[\(Date())] Switched TO \(currentLanguageName.capitalized) (non-default)")
        nonDefaultLanguageTimer.startNonDefaultLanguageSession(languageName: currentLanguageName)
    } else if switchedToDefault {
        nonDefaultLanguageTimer.stopNonDefaultLanguageSession()
    }
    
    // Update previous language for next check
    previousLanguageID = currentID

    // Main logic
    if !isCurrentlyDefault {
        // Currently in any non-default language
        
        // Record activity if user is currently typing
        if isCurrentlyTyping {
            nonDefaultLanguageTimer.recordNonDefaultLanguageActivity()
        }
        
        // Get non-default language idle time
        if let nonDefaultIdleTime = nonDefaultLanguageTimer.getNonDefaultLanguageIdleTime(),
           let currentLangName = nonDefaultLanguageTimer.getCurrentLanguageName() {
            print("[\(Date())] Active: \(currentName). \(currentLangName.capitalized) Idle Time: \(String(format: "%.1f", nonDefaultIdleTime))s. Typing: \(isCurrentlyTyping)")
            
            // Switch if idle long enough
            if nonDefaultIdleTime >= idleTimeout {
                print("[\(Date())] \(currentLangName.capitalized) idle time exceeded \(idleTimeout)s. Switching to \(defaultLanguageName.capitalized).")
                
                guard let sourceToSwitchTo = defaultSource else {
                    print("[\(Date())] Error: Default input source ('\(defaultInputSourceID)') not found.")
                    return
                }
                
                selectInputSource(sourceToSwitchTo)
                nonDefaultLanguageTimer.stopNonDefaultLanguageSession()
            }
        } else {
            let currentLanguageName = getLanguageNameFromID(currentID)
            print("[\(Date())] Active: \(currentName). \(currentLanguageName.capitalized) session not initialized.")
        }
    } else {
        // Currently in default language
        print("[\(Date())] Active: \(currentName) (\(defaultLanguageName.capitalized)). Status OK.")
    }
    
    // Flush output to ensure it appears immediately
    fflush(stdout)
    }
}

// MARK: - Command Line Argument Parsing

struct ProgramConfig {
    let timeout: TimeInterval
    let defaultLanguage: String
}

func parseCommandLineArguments() -> ProgramConfig {
    let arguments = CommandLine.arguments
    var timeout = defaultIdleTimeout
    var defaultLanguage = defaultDefaultLanguage
    
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
    
    return ProgramConfig(timeout: timeout, defaultLanguage: defaultLanguage)
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
    print("  KeyboardGuard                          # Any non-English -> English, 10s timeout")
    print("  KeyboardGuard -l portuguese            # Any non-Portuguese -> Portuguese, 10s timeout")
    print("  KeyboardGuard -t 30                    # Any non-English -> English, 30s timeout")
    print("  KeyboardGuard -l spanish -t 15         # Any non-Spanish -> Spanish, 15s timeout")
    print("  KeyboardGuard --language french --time 45  # Any non-French -> French, 45s timeout")
    print("")
    print("Backward Compatibility:")
    print("  KeyboardGuard 30                       # Any non-English -> English, 30s timeout")
}

// MARK: - Program Entry

let config = parseCommandLineArguments()
let keyboardGuard = KeyboardGuard(idleTimeout: config.timeout, defaultLanguage: config.defaultLanguage)

if keyboardGuard.defaultSource == nil {
    print("FATAL ERROR: The default input source could not be found. Please ensure \(config.defaultLanguage.capitalized) keyboard layout is enabled in Keyboard Settings > Input Sources.")
    exit(1)
} else {
    print("KeyboardGuard is starting.")
    print("Default language: \(config.defaultLanguage.capitalized)")
    print("Behavior: Any non-\(config.defaultLanguage) language -> \(config.defaultLanguage.capitalized)")
    print("Idle timeout: \(config.timeout) seconds")
    print("Check interval: \(checkInterval) seconds")
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