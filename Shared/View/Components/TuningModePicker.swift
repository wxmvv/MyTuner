//
//  TuningModePicker.swift
//  MyTuner
//
//  Created by wxm on 5/17/25.
//

import SwiftUI

struct TuningModePicker: View {
    @AppStorage("tuningMode") private var tuningMode = TuningMode.chromatic
    @AppStorage("instrument") private var instrument:Instrument = .Acoustic
    @StateObject var conductor: TunerConductor
    //    var onModeChanged: ((TuningMode) -> Void)?  //回调
    
    var body: some View {
        body_menu
    }
    
    var body_menu: some View{
        Menu {
            Button(TuningMode.chromatic.name, action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    tuningMode = .chromatic
                    conductor.tuningMode = .chromatic
                }
            })
            Divider()
            ForEach(instruments, id: \.self) { ins in
                Button(ins.name, action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        tuningMode = .instrument
                        conductor.tuningMode = .instrument
                        instrument = ins
                        conductor.instrument = ins
                    }
                })
            }
        } label: {
            HStack {
                if tuningMode == .instrument {
                    Text(instrument.name)
                } else {
                    Text(tuningMode.name)
                }
                Image(systemName: "chevron.down")
            }
        }
    }
    
    var body_picker: some View {
        Picker("TuningMode", selection: $tuningMode) {
            ForEach(tuningModes, id: \.self) { mode in
                Text(mode.name)
                    .tag(mode)
            }
        }
        .pickerStyle(.menu)
        .onChange(of: tuningMode) { newMode in
                conductor.tuningMode = newMode
        }
    }
}

@available(iOS 17, *)
#Preview(traits: .sizeThatFitsLayout){
    TuningModePicker( conductor: TunerConductor())
}
