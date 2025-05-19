//
//  Instrument.swift
//  MyTuner
//
//  Created by wxm on 4/2/25.
//

import Foundation


enum Instrument: String,CaseIterable {
    case Acoustic
    case Electric
    case Bass
    case Ukulele
    
    var name: String {
        switch self {
            case .Acoustic:
                return "Acoustic"
            case .Electric:
                return "Electric"
            case .Bass:
                return "Bass"
            case .Ukulele:
                return "Ukulele"
        }
    }
    
    var numberOfNotes: Int {
        switch self {
            case .Acoustic:
                return 6
            case .Electric:
                return 6
            case .Bass:
                return 4
            case .Ukulele:
                return 4
        }
    }
    
    func frequencys( referenceFrequency: Float = 440.0) -> [Float] {
        switch self {
            case .Acoustic:
                return self.notes(referenceFrequency: referenceFrequency).map { Note in
                    Note.frequency
                }
            case .Electric:
                return self.notes(referenceFrequency: referenceFrequency).map { Note in
                    Note.frequency
                }
            case .Bass:
                return self.notes(referenceFrequency: referenceFrequency).map { Note in
                    Note.frequency
                }
            case .Ukulele:
                return self.notes(referenceFrequency: referenceFrequency).map { Note in
                    Note.frequency
                }
        }
    }
    
    func midis(referenceFrequency: Float = 440.0) -> [Int] {
        switch self {
            case .Acoustic:
                return self.notes(referenceFrequency: referenceFrequency).map { Note in
                    Note.midi
                }
            case .Electric:
                return self.notes(referenceFrequency: referenceFrequency).map { Note in
                    Note.midi
                }
            case .Bass:
                return self.notes(referenceFrequency: referenceFrequency).map { Note in
                    Note.midi
                }
            case .Ukulele:
                return self.notes(referenceFrequency: referenceFrequency).map { Note in
                    Note.midi
                }
        }
    }
    


    func notes(referenceFrequency: Float = 440.0) -> [Note] {
        switch self {
            case .Acoustic:
                    // 标准吉他调音 (E2, A2, D3, G3, B3, E4)
                return [
                    Note(noteName: .E, octave: 2, referenceFrequency: referenceFrequency),
                    Note(noteName: .A, octave: 2, referenceFrequency: referenceFrequency),
                    Note(noteName: .D, octave: 3, referenceFrequency: referenceFrequency),
                    Note(noteName: .G, octave: 3, referenceFrequency: referenceFrequency),
                    Note(noteName: .B, octave: 3, referenceFrequency: referenceFrequency),
                    Note(noteName: .E, octave: 4, referenceFrequency: referenceFrequency)
                ]
            case .Electric:
                    // 标准吉他调音 (E2, A2, D3, G3, B3, E4)
                return [
                    Note(noteName: .E, octave: 2, referenceFrequency: referenceFrequency),
                    Note(noteName: .A, octave: 2, referenceFrequency: referenceFrequency),
                    Note(noteName: .D, octave: 3, referenceFrequency: referenceFrequency),
                    Note(noteName: .G, octave: 3, referenceFrequency: referenceFrequency),
                    Note(noteName: .B, octave: 3, referenceFrequency: referenceFrequency),
                    Note(noteName: .E, octave: 4, referenceFrequency: referenceFrequency)
                ]
            case .Bass:
                    // 标准四弦贝斯调音 (E1, A1, D2, G2)
                return [
                    Note(noteName: .E, octave: 1, referenceFrequency: referenceFrequency),
                    Note(noteName: .A, octave: 1, referenceFrequency: referenceFrequency),
                    Note(noteName: .D, octave: 2, referenceFrequency: referenceFrequency),
                    Note(noteName: .G, octave: 2, referenceFrequency: referenceFrequency)
                ]
            case .Ukulele:
                    // 标准尤克里里调音 (G4, C4, E4, A4)
                return [
                    Note(noteName: .G, octave: 4, referenceFrequency: referenceFrequency),
                    Note(noteName: .C, octave: 4, referenceFrequency: referenceFrequency),
                    Note(noteName: .E, octave: 4, referenceFrequency: referenceFrequency),
                    Note(noteName: .A, octave: 4, referenceFrequency: referenceFrequency)
                ]
        }
    }
}

