//
//  TunerView.swift
//  MyTuner
//
//  Created by wxm on 5/10/25.
//

import SwiftUI
import AudioKit


struct TunerView<TunerUI: View>: View {
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

    // The tuner UI content
    let tunerUI: (TunerData) -> TunerUI
    
    init(@ViewBuilder tunerUI: @escaping (TunerData) -> TunerUI) {
        self.tunerUI = tunerUI
    }
    
    
    var body: some View {
        AudioKitView(conductor: conductor) {
            ZStack {
                Color.white.opacity(0)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    // Top toolbar
                    MinimalTopToolbar(conductor: conductor, showSettingsSheet: $showSettingsSheet)
                    Spacer()
                    tunerUI(conductor.data)
                    Spacer()
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
            ListSettingsViewSheet(conductor: conductor,instrumentConductor: instrumentConductor, showSettingsSheet: $showSettingsSheet)
        }
    }
    
}

// Default initializer with CircleTuner
extension TunerView where TunerUI == CircleTuner {
    init() {
        self.init { tunerData in
            CircleTuner(tunerData: tunerData)
        }
    }
}


@available(iOS 17, *)
#Preview(traits: .fixedLayout(width: 500, height: 1000)){
    TunerView()
}
