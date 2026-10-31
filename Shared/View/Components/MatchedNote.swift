//
//  MatchedNote.swift
//  MyTuner
//
//  Created by wxm on 4/11/25.
//

import SwiftUI

struct MatchedNote: View {
    @AppStorage("preferredName") private var preferredName: ModifierPreference = .preferSharps
    var note: Note
    
    var body: some View {
        Text("\(note.noteName.mainNote(isSharp: preferredName.isSharp))")
            .font(.system(size: 100, design: .rounded))
            .fontWeight(.medium)
            .frame(height: 120)
            .overlay(alignment: .trailing) {
            VStack(alignment: .leading, spacing: 0) {
                Text("\(note.noteName.modifier(isSharp: preferredName.isSharp))")
                    .font(.system(size: 50, design: .rounded))
                Spacer()
                Text("\(note.octave)")
                    .font(.system(size: 35, design: .rounded))
            }
            .padding(.vertical, 10)
            .frame(height: 120)
            .alignmentGuide(.trailing) { $0[.leading] }
        }
        
    }
    
}

@available(iOS 17, *)
#Preview(traits: .sizeThatFitsLayout){
    MatchedNote(note: Note(midi: 73))
}
