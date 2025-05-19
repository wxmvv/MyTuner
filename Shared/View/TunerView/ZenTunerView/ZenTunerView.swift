//
//  DefaultTunerView.swift
//  MyTuner
//
//  Created by wxm on 3/26/25.
//

import SwiftUI
import AudioKit
import Tonic


struct ZenTunerView: View {
    @StateObject var conductor = TunerConductor()
    @StateObject var instrumentConductor = InstrumentConductor()
    
    @AppStorage("smoothingFactor") private var smoothingFactor: Double = 0.5
    @AppStorage("inTuneRange") private var inTuneRange: Int = 2
    @AppStorage("pitchStandard") private var pitchStandard = 440
    @AppStorage("amplitudeLimit") private var amplitudeLimit: Double = 0.2
    @AppStorage("preferredName") private var preferredName: ModifierPreference = .preferSharps
    @AppStorage("tuningMode") private var tuningMode: TuningMode = .chromatic
    @AppStorage("instrument") private var instrument: Instrument = .Acoustic
    
    @AppStorage("velocity") var velocity:Int = 100
    @AppStorage("instrumentIndex") var instrumentIndex:Int = 0
    
    @State private var showSettingsSheet = false
    
    var body: some View {
        ZStack {
            //  Color.black.edgesIgnoringSafeArea(.all)
            GeometryReader { geo in
                
                
                MinimalTopToolbar(conductor: conductor, showSettingsSheet: $showSettingsSheet)
                
                
                
                VStack(spacing: 0) {
                    // Top bar with mode and settings
                    Spacer()
                    
                    // Note buttons row - dynamically based on current tuner mode
                    HStack(spacing: 15) {
                        Text(Note(midi: conductor.data.targetMidi, referenceFrequency: Float(pitchStandard)).noteName.noteName(isSharp: preferredName == .preferSharps ))
                            .foregroundColor(conductor.isInTune ? .green : conductor.isOutOfTune ? .red : .yellow)
                            .font(.system(size: 60))
                        
                    }
                    
                    Spacer()
                    
                    VStack(spacing:0) {
                        // Note detection result
                        NoteTicks(tunerData: conductor.data)
                        
                        // Frequency label
                        Text("\(Int(conductor.data.pitch))Hz")
                            .foregroundColor(.gray)
                            .padding()
                    }
                    
                    Spacer()
                    Spacer()
                    
                }
                if tuningMode == .instrument {
                    MinimalInstrumentView(instrumentConductor: instrumentConductor, conductor: conductor)
                }
                
            }
        }
        .onAppear {
            conductor.setup(amplitudeLimit: Float(amplitudeLimit), pitchStandard: Float(pitchStandard), smoothingFactor: Float(smoothingFactor), inTuneRange: inTuneRange, outOfTuneRange: 20, tuningMode: tuningMode, instrument: instrument)
            conductor.start()
            instrumentIndex = max(0, min(instrumentIndex, availableInstruments.count - 1))
            instrumentConductor.setup(velocity: MIDIVelocity(velocity), instrumentIndex: instrumentIndex)
            instrumentConductor.start()
        }
        .onDisappear {
            conductor.stop()
            instrumentConductor.stop()
        }
        .sheet(isPresented: $showSettingsSheet) {
            ListSettingsView(conductor: conductor, instrumentConductor: instrumentConductor,isSheet: true)
                .presentationBackground(Material.regular)
        }
    }
    
    
}



@available(iOS 17, *)
#Preview(traits: .fixedLayout(width: 500, height: 800)){
    ZenTunerView()
}

