//
//  CircleTunerView.swift
//  MyTuner
//
//  Created by wxm on 5/10/25.
//

import SwiftUI
import AudioKit


struct CircleTunerView: View {
    @StateObject var conductor = TunerConductor()
    @StateObject var instrumentConductor = InstrumentConductor()
    
    @AppStorage("smoothingFactor") private var smoothingFactor: Double = 0.5
    @AppStorage("inTuneRange") private var inTuneRange: Int = TunerDefaults.inTuneRange
    @AppStorage("pitchStandard") private var pitchStandard = TunerDefaults.pitchStandard
    @AppStorage("amplitudeLimit") private var amplitudeLimit: Double = TunerDefaults.amplitudeLimit
    @AppStorage("preferredName") private var preferredName: ModifierPreference = .preferSharps
    @AppStorage("tuningMode") private var tuningMode: TuningMode = .chromatic
    @AppStorage("instrument") private var instrument: Instrument = .Acoustic
    
    @AppStorage("velocity") var velocity:Int = 100
    @AppStorage("instrumentIndex") var instrumentIndex:Int = 0
    
    @State private var showSettingsSheet = false
    @State private var showMetronome = false
    
    var body: some View {
        NavigationStack {
            Group {
                if showMetronome {
                    MetronomeView()
                } else {
                    tunerPage
                }
            }
            .sheet(isPresented: $showSettingsSheet) {
                ListSettingsView(conductor: conductor, instrumentConductor: instrumentConductor,
                                 isSheet: true, metronomeFirst: showMetronome)
                    .presentationBackground(Material.regular)
            }
            .toolbar {
                if !showMetronome {
                    ToolbarItem(placement: .navigationBarLeading) {
                        TuningModePicker(conductor: conductor, toolbarLabel: true)
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        showMetronome.toggle()
                    } label: {
                        Label {
                            if showMetronome {
                                Text("Tuner")
                            } else {
                                Text("Metronome")
                            }
                        } icon: {
                            Image(systemName: showMetronome ? "tuningfork" : "metronome")
                        }
                    }

                    Button {
                        showSettingsSheet = true
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
            }
            .tint(.primary)
        }
    }

    private var tunerPage: some View {
        ZStack {
            Color.white.opacity(0)
                .edgesIgnoringSafeArea(.all)
            CircleTuner(tunerData: conductor.data)
                .ignoresSafeArea()

            if tuningMode == .instrument {
                VStack(spacing: 0) {
                    Spacer()
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
    }
}


@available(iOS 17, *)
#Preview(traits: .fixedLayout(width: 500, height: 1000)){
    CircleTunerView()
}
