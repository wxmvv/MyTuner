//
//  TuningMode.swift
//  MyTuner
//
//  Created by wxm on 4/6/25.
//


enum TuningMode:String,CaseIterable {
    case chromatic
    case instrument
    
    var name: String {
        switch self {
            case .chromatic:
                return "Chromatic"
            case .instrument:
                return "Instrument"

        }
    }
}
