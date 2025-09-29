import Foundation
// The Carbon module contains the necessary C functions for Text Input Services (TIS).
import Carbon
// AppKit for NSEvent.addLocalMonitorForEvents fallback
import AppKit
// IOKit for system idle time detection via HIDIdleTime
import IOKit

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
var globalConfig: Configuration!

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
            checkInterval: 2.0
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
            checkInterval: 2.0
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
let supportedLanguages = globalConfig.supportedLanguages
let defaultIdleTimeout = globalConfig.defaultConfiguration.idleTimeout
let defaultDefaultLanguage = globalConfig.defaultConfiguration.defaultLanguage
let checkInterval = globalConfig.defaultConfiguration.checkInterval

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

/// Gets system idle time using IOKit HIDIdleTime - more reliable than AppKit events
class SystemIdleTimeMonitor {
    
    init() {
        print("System idle time monitor initialized...")
    }
    
    /// Gets the system idle time in seconds using IOKit
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
    // Monitor system idle time
    private let systemIdleMonitor = SystemIdleTimeMonitor()
    // Manage non-default language-specific idle timing
    private let nonDefaultLanguageTimer = NonDefaultLanguageTimer()
    // Configurable idle timeout
    private let idleTimeout: TimeInterval
    // Default language info (what to switch TO)
    private let defaultInputSourceID: String
    private let defaultLanguageName: String
    // Track previous language to detect switches
    private var previousLanguageID: String?
    // Track previous global idle time to detect typing
    private var previousGlobalIdleTime: TimeInterval = 0
    
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
        
        print("Note: Using system idle time via IOKit for reliable typing detection.")
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
    
    // Get current system idle time
    let systemIdleTime = systemIdleMonitor.getSystemIdleTime()
    let isCurrentlyTyping = systemIdleTime < 1.0 // Consider "typing" if system idle < 1 second
    
    // Handle non-default language session management
    if switchedToNonDefault {
        let currentLanguageName = getLanguageNameFromID(currentID)
        print("[\(Date())] Switched TO \(currentLanguageName.capitalized) (non-default)")
        nonDefaultLanguageTimer.startNonDefaultLanguageSession(languageName: currentLanguageName)
        // IMPORTANT: Reset timer immediately when switching to secondary language
        nonDefaultLanguageTimer.recordNonDefaultLanguageActivity()
        print("[\(Date())] Timer reset due to language switch")
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
        let typingDetected = systemIdleTime < previousGlobalIdleTime || systemIdleTime < 0.5
        
        if typingDetected && nonDefaultLanguageTimer.isInNonDefaultLanguageSession() {
            nonDefaultLanguageTimer.recordNonDefaultLanguageActivity()
            print("[\(Date())] Timer reset due to typing detected (system idle: \(String(format: "%.1f", systemIdleTime))s, prev: \(String(format: "%.1f", previousGlobalIdleTime))s)")
        }
        
        // Update previous idle time for next comparison
        previousGlobalIdleTime = systemIdleTime
        
        // Use secondary language timer for switching decision
        if let secondaryIdleTime = nonDefaultLanguageTimer.getNonDefaultLanguageIdleTime() {
            print("[\(Date())] Active: \(currentName). \(currentLanguageName.capitalized) Idle Time: \(String(format: "%.1f", secondaryIdleTime))s. System: \(String(format: "%.1f", systemIdleTime))s. Typing: \(isCurrentlyTyping)")
            
            // Switch based on secondary language idle time
            if secondaryIdleTime >= idleTimeout {
                print("[\(Date())] \(currentLanguageName.capitalized) idle time exceeded \(idleTimeout)s. Switching to \(defaultLanguageName.capitalized).")
                
                guard let sourceToSwitchTo = defaultSource else {
                    print("[\(Date())] Error: Default input source ('\(defaultInputSourceID)') not found.")
                    return
                }
                
                selectInputSource(sourceToSwitchTo)
                nonDefaultLanguageTimer.stopNonDefaultLanguageSession()
            }
        } else {
            print("[\(Date())] Active: \(currentName). \(currentLanguageName.capitalized) timer not initialized.")
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

let cmdConfig = parseCommandLineArguments()
let keyboardGuard = KeyboardGuard(idleTimeout: cmdConfig.timeout, defaultLanguage: cmdConfig.defaultLanguage)

if keyboardGuard.defaultSource == nil {
    print("FATAL ERROR: The default input source could not be found. Please ensure \(cmdConfig.defaultLanguage.capitalized) keyboard layout is enabled in Keyboard Settings > Input Sources.")
    exit(1)
} else {
    print("KeyboardGuard is starting.")
    print("Default language: \(cmdConfig.defaultLanguage.capitalized)")
    print("Behavior: Any non-\(cmdConfig.defaultLanguage) language -> \(cmdConfig.defaultLanguage.capitalized)")
    print("Idle timeout: \(cmdConfig.timeout) seconds")
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