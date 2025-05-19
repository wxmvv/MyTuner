//
//  AudioKitView.swift
//  MyTuner
//
//  Created by wxm on 4/7/25.
//

import SwiftUI

struct AudioKitView<Content: View> : View {
    @AppStorage("smoothingFactor") private var smoothingFactor = 0.5
    @AppStorage("inTuneRange") private var inTuneRange = 2
    @AppStorage("pitchStandard") private var pitchStandard = 440
    @AppStorage("amplitudeLimit") private var amplitudeLimit = 0.075
    @AppStorage("preferredName") private var preferredName: ModifierPreference = .preferSharps
    @AppStorage("tuningMode") private var tuningMode: TuningMode = .chromatic
    @AppStorage("instrument") private var instrument: Instrument = .Acoustic
    
    let content: Content
    var conductor: TunerConductor
    
    init( conductor: TunerConductor,@ViewBuilder content: () -> Content) {
        self.content = content()
        self.conductor = conductor
    }
    
    var body: some View {
        VStack(spacing: 0){
            content
        }
        .onAppear {
            conductor.amplitudeLimit = Float(amplitudeLimit)
            conductor.pitchStandard = Float(pitchStandard)
            conductor.smoothingFactor = Float(smoothingFactor)
            conductor.tuningMode = tuningMode
            conductor.instrument = instrument
            conductor.start()
        }
        .onDisappear {
            conductor.stop()
        }
        
    }
}

