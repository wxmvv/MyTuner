//
//  TunerOne.swift
//  MyTuner
//
//  Created by wxm on 4/11/25.
//

import SwiftUI


struct TunerOne: View {
    var tunerData: TunerData
    
    var body: some View {
        VStack{
            NoteTickOne(tunerData: tunerData)
            MatchedNote(note: tunerData.targetNote)
        }
        .overlay(alignment: .center, content: {
            RoundedRectangle(cornerRadius: 10)
                .stroke(.primary, lineWidth: 1)
        })

        
    }
}

struct NoteTickOne: View {
    var tunerData: TunerData
    @AppStorage("inTuneRange") private var inTuneRange: Int = 2
    
    var body: some View {
        MarkDistance(inTuneCents: Float(inTuneRange))
            .overlay {
                CurrentMark(tunerData: tunerData)
            }
    }
}



@available(iOS 17, *)
#Preview(traits: .fixedLayout(width: 300, height: 300)){
    TunerOne(tunerData: TunerData())
}

@available(iOS 17, *)
#Preview(traits: .fixedLayout(width: 300, height: 100)){
    NoteTickOne(tunerData: TunerData())
}
