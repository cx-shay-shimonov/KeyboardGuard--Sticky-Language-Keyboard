#!/usr/bin/env swift

import Foundation
import Carbon

// Helper script to find macOS input source IDs for adding to languages.json

/// Gets all available input sources on the current system
func getAllInputSources() -> [(id: String, name: String)] {
    var sources: [(id: String, name: String)] = []
    
    // Get all input sources
    guard let inputSources = TISCreateInputSourceList(nil, false)?.takeRetainedValue() as? [TISInputSource] else {
        return sources
    }
    
    for source in inputSources {
        var sourceID = "Unknown ID"
        var sourceName = "Unknown Name"
        
        // Get source ID
        if let idProperty = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) {
            sourceID = Unmanaged<CFString>.fromOpaque(idProperty).takeUnretainedValue() as String
        }
        
        // Get localized name
        if let nameProperty = TISGetInputSourceProperty(source, kTISPropertyLocalizedName) {
            sourceName = Unmanaged<CFString>.fromOpaque(nameProperty).takeUnretainedValue() as String
        }
        
        // Only include keyboard layouts
        if sourceID.contains("keylayout") {
            sources.append((id: sourceID, name: sourceName))
        }
    }
    
    return sources.sorted { $0.name < $1.name }
}

print("Available macOS Keyboard Input Sources:")
print("=====================================")
print("")

let sources = getAllInputSources()

if sources.isEmpty {
    print("No keyboard input sources found.")
} else {
    print("Format for languages.json:")
    print("\"language-name\": \"input-source-id\"")
    print("")
    
    for source in sources {
        print("// \(source.name)")
        print("\"your-name\": \"\(source.id)\"")
        print("")
    }
}

print("Usage:")
print("1. Copy the input source ID for your desired language")
print("2. Add it to languages.json with your preferred name")
print("3. Restart KeyboardGuard")
