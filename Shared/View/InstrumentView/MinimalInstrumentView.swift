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
        GeometryReader { geometry in
            let notes = instrument.notes(referenceFrequency: Float(pitchStandard))
            if let panes = FoldPanes(geometry) {
                if panes.axis == .horizontal {
                    let split = (notes.count + 1) / 2
                    HStack(spacing: panes.spacing) {
                        noteStrip(Array(notes.prefix(split)))
                            .frame(width: panes.before.width, height: panes.before.height)
                            .clipped()
                        noteStrip(Array(notes.dropFirst(split)))
                            .frame(width: panes.after.width, height: panes.after.height)
                            .clipped()
                    }
                } else {
                    let useAfter = panes.after.height >= panes.before.height
                    let height = useAfter ? panes.after.height : panes.before.height
                    noteStrip(notes, diameter: min(50, height))
                        .frame(height: height)
                        .clipped()
                        .offset(y: useAfter ? panes.before.height + panes.spacing : 0)
                }
            } else {
                noteStrip(notes)
                    .frame(height: geometry.size.height)
            }
        }
        .frame(height: 80)
    }

    private func noteStrip(_ notes: [Note], diameter: CGFloat = 50) -> some View {
        ViewThatFits(in: .horizontal) {
            noteButtons(notes, diameter: diameter, spacing: 12).padding(.horizontal, 6)
            noteButtons(notes, diameter: diameter, spacing: 0)
            ScrollView(.horizontal) {
                noteButtons(notes, diameter: diameter, spacing: 6).padding(.horizontal, 6)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .frame(maxWidth: .infinity)
    }

    private func noteButtons(_ notes: [Note], diameter: CGFloat, spacing: CGFloat) -> some View {
        HStack(spacing: spacing) {
            ForEach(notes) { note in
                Button {
                    instrumentConductor.playNote(note: MIDINoteNumber(note.midi), pitchStandard: pitchStandard)
                } label: {
                    noteButtonLabel(note.noteNameString, diameter: diameter,
                                    isSelected: dev || conductor.data.targetMidi == note.midi)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func noteButtonLabel(_ title: String, diameter: CGFloat, isSelected: Bool) -> some View {
        let label = Text(title)
            .foregroundColor(.primary)
            .font(.title2.weight(.bold))
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .frame(width: diameter, height: diameter)
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

