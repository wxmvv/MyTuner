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
    var toolbarLabel = false
    //    var onModeChanged: ((TuningMode) -> Void)?  //回调
    
    var body: some View {
        body_menu
    }
    
    var body_menu: some View{
        Menu {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    tuningMode = .chromatic
                    conductor.tuningMode = .chromatic
                }
            }) {
                Label(TuningMode.chromatic.name, systemImage: TuningMode.chromatic.symbolName)
            }
            Divider()
            ForEach(instruments, id: \.self) { ins in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        tuningMode = .instrument
                        conductor.tuningMode = .instrument
                        instrument = ins
                        conductor.instrument = ins
                    }
                }) {
                    Label(ins.name, systemImage: ins.symbolName)
                }
            }
        } label: {
            if toolbarLabel {
                Label(tuningMode == .instrument ? instrument.name : tuningMode.name,
                      systemImage: tuningMode == .instrument ? instrument.symbolName : tuningMode.symbolName)
            } else {
                HStack {
                    Image(systemName: tuningMode == .instrument ? instrument.symbolName : tuningMode.symbolName)
                    if tuningMode == .instrument {
                        Text(instrument.name)
                    } else {
                        Text(tuningMode.name)
                    }
                    Image(systemName: "chevron.down")
                }
            }
        }
    }
    
    var body_picker: some View {
        Picker("Tuning Mode", selection: $tuningMode) {
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
