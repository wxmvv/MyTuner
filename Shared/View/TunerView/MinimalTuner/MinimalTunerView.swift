//
//  MinimalTunerView.swift
//  MyTuner
//
//  Created by wxm on 3/26/25.
//

import AudioKit
import SwiftUI


struct MinimalTunerView: View {
    @StateObject var conductor = TunerConductor()
    
    @AppStorage("smoothingFactor") private var smoothingFactor: Double = 0.5
    @AppStorage("inTuneRange") private var inTuneRange: Int = 2
    @AppStorage("pitchStandard") private var pitchStandard = 440
    @AppStorage("amplitudeLimit") private var amplitudeLimit: Double = 0.2
    @AppStorage("preferredName") private var preferredName: ModifierPreference = .preferSharps
    @AppStorage("tuningMode") private var tuningMode: TuningMode = .chromatic
    @AppStorage("instrument") private var instrument: Instrument = .Acoustic
    
    @State private var showSettingsSheet = false
    
    var body: some View {
        VStack {
            MinimalTopToolbar(conductor: conductor, showSettingsSheet: $showSettingsSheet)
            VStack{
                AmplitudeLimitPicker(conductor: conductor)
                Text("Pitch: \(conductor.data.pitch, specifier: "%0.2f")")
                Text("Amplitude: \(conductor.data.amplitude, specifier: "%0.2f")")
                Text("Note Name: \(conductor.data.noteNameWithSharps) / \(conductor.data.noteNameWithFlats)")
                Text("targetFrequency: \(conductor.data.targetFrequency, specifier: "%0.2f")")
                Text("targetMidi: \(conductor.data.targetMidi)")
                Text("targetMidi noteName \(Note(midi: conductor.data.targetMidi, referenceFrequency: Float(pitchStandard)).noteName.noteName(isSharp: preferredName == .preferSharps))")
                Text("frequencyDistance Float: \(conductor.data.frequencyDistance, specifier: "%0.2f")")
                Text("frequencyDistance Int: \(conductor.data.frequencyDistance, specifier: "%0.0f")")
                Text("cents: \(conductor.data.cents,specifier: "%0.2f")")
                Text("isPitchHigh: \(conductor.data.isPitchHigh)")
                Spacer()
            }
            .onAppear {
                conductor.amplitudeLimit = Float(amplitudeLimit)
                conductor.pitchStandard = Float(pitchStandard)
                conductor.smoothingFactor = Float(smoothingFactor)
                conductor.inTuneRange = inTuneRange
                conductor.outOfTuneRange = 20
                conductor.tuningMode = tuningMode
                conductor.instrument = instrument
                conductor.start()
            }
            .onDisappear {
                conductor.stop()
            }
            .sheet(isPresented: $showSettingsSheet,onDismiss: {
            }) {
                VStack(spacing:0){
                        //  CustomSettingsView()
                    ListSettingsView(conductor: conductor)
                    
                    Button {
                        showSettingsSheet = false
                    } label: {
                        HStack{
                            Text("Close")
                                .foregroundColor(.primary)
                                .padding(10)
                                .background(Color.primary.opacity(0.15))
                                .cornerRadius(10)
                        }
                        .padding(10)
                    }
                }
            }
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            conductor.data.cents==0 ? Color.white.opacity(0):
                conductor.isInTune ? .green.opacity(0.5) : conductor.isOutOfTune ? .red.opacity(0.5) : .yellow.opacity(0.5)
        )
        .navigationTitle("Default Tuner View")
    }
}




@available(iOS 17, *)
#Preview(traits: .fixedLayout(width: 500, height: 1000)){
    MinimalTunerView()
}
