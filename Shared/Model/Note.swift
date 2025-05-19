//
//  Note.swift
//  MyTuner
//
//  Created by wxm on 4/4/25.
//

import Foundation


struct Note: Identifiable {
    let id: Int // UUID()
    let noteName: NoteName
    let noteNameString: String
    let frequency:Float
    let midi:Int
    let octave:Int
    
        // 初始化方法1：基于MIDI编号
    init(midi: Int, referenceFrequency: Float = 440.0) {
        self.id = midi
        self.midi = midi
        self.octave = midi / 12 - 1  // 计算八度（C-1的MIDI是0）
        let noteIndex = midi % 12    // 计算12音中的位置
        self.noteName = NoteName.allCases[noteIndex]
        self.noteNameString = noteName.noteName()
        self.frequency = referenceFrequency * powf(2.0, Float(midi - 69) / 12.0)
    }
    
        // 初始化方法2：基于音符名称和八度
    init(noteName: NoteName, octave: Int, referenceFrequency: Float = 440.0) {
        self.noteName = noteName
        self.noteNameString = noteName.noteName()
        self.octave = octave
        self.midi = (octave + 1) * 12 + noteName.index  // 计算MIDI编号
        self.id = self.midi
        self.frequency = referenceFrequency * powf(2.0, Float(self.midi - 69) / 12.0)
    }
}


enum NoteName:String ,CaseIterable{
    case C, CSharp_DFlat, D, DSharp_EFlat, E, F, FSharp_GFlat, G, GSharp_AFlat, A, ASharp_BFlat, B
    
    func noteName(isSharp:Bool = true)->String{
        return isSharp ? self.noteNameWithSharps : self.noteNameWithFlats
    }
    
    // notename 升降部分
    func mainNote(isSharp:Bool)->String{
        return isSharp ? self.mainNoteWithSharp : self.mainNoteWithFlat
    }
    
    func modifier(isSharp:Bool)->String{
        return isSharp ? self.modifierWithSharp : self.modifierWithFlat
    }
    
    var mainNoteWithSharp: String {
        switch self {
            case .C:              return "C"
            case .CSharp_DFlat:   return "C"
            case .D:              return "D"
            case .DSharp_EFlat:   return "D"
            case .E:              return "E"
            case .F:              return "F"
            case .FSharp_GFlat:   return "F"
            case .G:              return "G"
            case .GSharp_AFlat:   return "G"
            case .A:              return "A"
            case .ASharp_BFlat:   return "A"
            case .B:              return "B"
        }
    }
    var mainNoteWithFlat: String {
        switch self {
            case .C:              return "C"
            case .CSharp_DFlat:   return "D"
            case .D:              return "D"
            case .DSharp_EFlat:   return "E"
            case .E:              return "E"
            case .F:              return "F"
            case .FSharp_GFlat:   return "G"
            case .G:              return "G"
            case .GSharp_AFlat:   return "A"
            case .A:              return "A"
            case .ASharp_BFlat:   return "B"
            case .B:              return "B"
        }
    }
    var modifierWithSharp: String {
        switch self {
            case .C:              return ""
            case .CSharp_DFlat:   return "♯"
            case .D:              return ""
            case .DSharp_EFlat:   return "♯"
            case .E:              return ""
            case .F:              return ""
            case .FSharp_GFlat:   return "♯"
            case .G:              return ""
            case .GSharp_AFlat:   return "♯"
            case .A:              return ""
            case .ASharp_BFlat:   return "♯"
            case .B:              return ""
        }
    }
    var modifierWithFlat: String {
        switch self {
            case .C:              return ""
            case .CSharp_DFlat:   return "♭"
            case .D:              return ""
            case .DSharp_EFlat:   return "♭"
            case .E:              return ""
            case .F:              return ""
            case .FSharp_GFlat:   return "♭"
            case .G:              return ""
            case .GSharp_AFlat:   return "♭"
            case .A:              return ""
            case .ASharp_BFlat:   return "♭"
            case .B:              return ""
        }
    }
    
    
    var noteNameWithSharps: String {
        switch self {
            case .C:              return "C"
            case .CSharp_DFlat:   return "C♯"
            case .D:              return "D"
            case .DSharp_EFlat:   return "D♯"
            case .E:              return "E"
            case .F:              return "F"
            case .FSharp_GFlat:   return "F♯"
            case .G:              return "G"
            case .GSharp_AFlat:   return "G♯"
            case .A:              return "A"
            case .ASharp_BFlat:   return "A♯"
            case .B:              return "B"
        }
    }
    var noteNameWithFlats: String {
        switch self {
            case .C:              return "C"
            case .CSharp_DFlat:   return "D♭"
            case .D:              return "D"
            case .DSharp_EFlat:   return "E♭"
            case .E:              return "E"
            case .F:              return "F"
            case .FSharp_GFlat:   return "G♭"
            case .G:              return "G"
            case .GSharp_AFlat:   return "A♭"
            case .A:              return "A"
            case .ASharp_BFlat:   return "B♭"
            case .B:              return "B"
        }
    }
    
    var solfege: String {
        switch self {
            case .C: return "Do"
            case .CSharp_DFlat: return "Di"
            case .D: return "Re"
            case .DSharp_EFlat: return "Ri"
            case .E: return "Mi"
            case .F: return "Fa"
            case .FSharp_GFlat: return "Fi"
            case .G: return "Sol"
            case .GSharp_AFlat: return "Si"
            case .A: return "La"
            case .ASharp_BFlat: return "Li"
            case .B: return "Si"
        }
    }
    
        // 获取NoteName对应的索引（用于MIDI计算）
    var index: Int {
        return NoteName.allCases.firstIndex(of: self) ?? 0
    }
}

