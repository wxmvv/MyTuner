import SwiftUI

// Case order preserves the stored instrumentIndex. Raw values are MIDI programs in the sound bank.
enum InstrumentDefinition: Int, CaseIterable {
    case guitar = 24
    case piano = 0
    case bass = 33
    case marimba = 12

    var displayName: LocalizedStringKey {
        switch self {
        case .guitar: return "Guitar"
        case .piano: return "Piano"
        case .bass: return "Bass"
        case .marimba: return "Marimba"
        }
    }
}

let availableInstruments = InstrumentDefinition.allCases
