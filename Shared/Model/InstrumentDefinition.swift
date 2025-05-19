//
//  InstrumentDefinition.swift
//  MyTuner
//
//  Created by wxm on 4/18/25.
//

import Foundation
import SwiftUI

struct InstrumentDefinition: Identifiable {
    let id = UUID() // For Identifiable conformance, useful for Picker
    let displayName: LocalizedStringKey // Name shown in the UI (e.g., "Classical Guitar")
    let fileName: String    // File name without extension (e.g., "Classical Acoustic Guitar")
    let fileExtension: String // "exs" or "sf2"
    let subdirectory: String? // Optional subdirectory (e.g., "Sounds/Logic SI/01 Acoustic Guitars")
    
    // For SF2 files, you might need preset and bank
    var sf2Preset: Int? = nil // Default to nil if not SF2
    var sf2Bank: Int? = nil   // Default to nil if not SF2
    let needsAutoStop: Bool // 标志位，指示是否需要自动停止
    let autoStopDelay: TimeInterval // 自动停止前的延迟时间 (秒)
    
    // Initializer for common cases (like EXS)
    init(displayName: LocalizedStringKey, fileName: String, fileExtension: String, subdirectory: String?,needsAutoStop: Bool = false, autoStopDelay: TimeInterval = 1.5) {
        self.displayName = displayName
        self.fileName = fileName
        self.fileExtension = fileExtension
        self.subdirectory = subdirectory
        self.needsAutoStop = needsAutoStop
        self.autoStopDelay = autoStopDelay
    }
    
    // Initializer specifically for SF2 if needed
    init(displayName: LocalizedStringKey, fileName: String, subdirectory: String?, preset: Int, bank: Int = 0,needsAutoStop: Bool = false, autoStopDelay: TimeInterval = 1.5) {
        self.displayName = displayName
        self.fileName = fileName
        self.fileExtension = "sf2" // Assume SF2
        self.subdirectory = subdirectory
        self.sf2Preset = preset
        self.sf2Bank = bank
        self.needsAutoStop = needsAutoStop
        self.autoStopDelay = autoStopDelay
    }
    
    var file: String {
        return (subdirectory != nil) ? subdirectory! + "/" : ""  + fileName
    }
    
    // Convenience computed property for Picker label
    var label: LocalizedStringKey {
        return displayName
    }
}
