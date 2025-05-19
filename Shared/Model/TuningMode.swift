//
//  TuningMode.swift
//  MyTuner
//
//  Created by wxm on 4/6/25.
//

import SwiftUI

enum TuningMode:String,CaseIterable {
    case chromatic = "Chromatic"
    case instrument = "Instrument"
    
    var name: LocalizedStringKey {
        switch self {
            case .chromatic:
                return "Chromatic"
            case .instrument:
                return "Instrument"

        }
    }
    
}
