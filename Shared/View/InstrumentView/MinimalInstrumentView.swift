//
//  MinimalInstrumentView.swift
//  MyTuner
//
//  Created by wxm on 5/16/25.
//

import SwiftUI
import AudioKit
import Tonic

struct MinimalInstrumentView: View {
    var instrumentConductor: InstrumentConductor
    var conductor: TunerConductor
    @AppStorage("instrument") private var instrument: Instrument = .Acoustic
    @AppStorage("pitchStandard") private var pitchStandard = 440
    
    var dev = false
    
    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                ForEach(instrument.notes(referenceFrequency: Float(pitchStandard))) { note in
                    Button {
                        print("note.frequency \(note.frequency)")
                        instrumentConductor.playNote(note:MIDINoteNumber(note.midi))
                    } label :{
                        VStack(spacing: 5) {
                            ZStack {
                                Circle()
                                // .fill(conductor.data.targetMidi == note.midi ? conductor.isInTune ? .green : conductor.isOutOfTune ? .red : .yellow : Color.gray.opacity(0.3))
                                // TODO 动态效果
                                    .fill(
                                        dev ? Color(uiColor: .systemGray2) :
                                            conductor.data.targetMidi == note.midi ? Color(uiColor:.systemGray2) : Color(uiColor: .systemGray5))
                                    .frame(width: 50, height: 50)
                                Text(note.noteNameString)
                                    .foregroundColor(.primary)
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                        }
                        .padding(.horizontal,6)
                        .padding(.vertical)
                        .shadow(
                            color: Color(uiColor:.systemGray).opacity(0.2),
                            radius: 6, x: 6, y: 6
                        )
                    }
                }
                
            }
            .frame(width: geo.size.width, height: 80)
//            .background(.yellow)
        }
        .frame(height: 80)
//        .background(.red)
    }
}

@available(iOS 17, *)
#Preview(traits: .fixedLayout(width: 500, height: 400)){
    MinimalInstrumentView(instrumentConductor: InstrumentConductor(), conductor: TunerConductor())
        .preferredColorScheme(.light)
    MinimalInstrumentView(instrumentConductor: InstrumentConductor(), conductor: TunerConductor(), dev: true)
        .preferredColorScheme(.light)

}

@available(iOS 17, *)
#Preview(traits: .fixedLayout(width: 500, height: 400)){
    MinimalInstrumentView(instrumentConductor: InstrumentConductor(), conductor: TunerConductor())
        .preferredColorScheme(.dark)
    MinimalInstrumentView(instrumentConductor: InstrumentConductor(), conductor: TunerConductor(), dev: true)
        .preferredColorScheme(.dark)
}

