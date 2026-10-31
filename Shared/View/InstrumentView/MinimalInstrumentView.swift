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
                        noteButtonLabel(note.noteNameString, isSelected: dev || conductor.data.targetMidi == note.midi)
                            .padding(.horizontal, 6)
                            .padding(.vertical)
                    }
                    .buttonStyle(.plain)
                }
                
            }
            .frame(width: geo.size.width, height: 80)
//            .background(.yellow)
        }
        .frame(height: 80)
//        .background(.red)
    }
    @ViewBuilder
    private func noteButtonLabel(_ title: String, isSelected: Bool) -> some View {
        let label = Text(title)
            .foregroundColor(.primary)
            .font(.title2.weight(.bold))
            .frame(width: 50, height: 50)
            .contentShape(Circle())

        if #available(iOS 26.0, *) {
            label.glassEffect(
                isSelected ? .regular.tint(.gray.opacity(0.45)).interactive() : .regular.interactive(),
                in: Circle()
            )
        } else {
            label
                .background(.regularMaterial, in: Circle())
                .overlay {
                    Circle().fill(Color.primary.opacity(isSelected ? 0.18 : 0.04))
                }
                .overlay {
                    Circle().strokeBorder(Color.primary.opacity(isSelected ? 0.24 : 0.1), lineWidth: 1)
                }
        }
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

