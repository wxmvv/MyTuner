//
//  ModifierPreference.swift
//  MyTuner
//
//  Created by wxm on 4/2/25.
//

import SwiftUI

enum ModifierPreference: Int, Identifiable, CaseIterable {
    case preferSharps, preferFlats
    
    var isSharp: Bool {
        switch self {
        case .preferSharps:
            return true
        case .preferFlats:
            return false
        }
    }
    
    var name: LocalizedStringKey {
        switch self {
        case .preferSharps:
            return "Sharps"
        case .preferFlats:
            return "Flats"
        }
    }

    var toggled: ModifierPreference {
        switch self {
        case .preferSharps:
            return .preferFlats
        case .preferFlats:
            return .preferSharps
        }
    }

    var id: Int { rawValue }
}
