//
//  AmplitudeLimitPicker.swift
//  MyTuner
//
//  Created by wxm on 4/6/25.
//

import SwiftUI

struct AmplitudeLimitPicker: View {
    @AppStorage("amplitudeLimit") private var amplitudeLimit = 0.2
    @StateObject var conductor: TunerConductor
    
    var body: some View {
        body_menu
    }
    
    var body_picker: some View {
        Picker("Amplitude Limit", selection: $amplitudeLimit) {
            ForEach(amplitudeLimitValues, id: \.self) { limit in
                Text("Amplitude Limit \(String(limit))").tag(limit)
            }
        }
        .pickerStyle(.menu)
        .onChange(of: amplitudeLimit) { newLimit in
            conductor.amplitudeLimit = Float(newLimit)
        }
    }
    
    var body_menu: some View{
        Menu {
            ForEach(amplitudeLimitValues, id: \.self) { limit in
                Button("\(String(limit))", action: {
                    amplitudeLimit = limit
                    conductor.amplitudeLimit = Float(limit)
                })
            }
        } label: {
            HStack {
                Text("Amplitude Limit \(String(amplitudeLimit))")
                Image(systemName: "chevron.down")
            }
        }
    }
}

@available(iOS 17, *)
#Preview(traits: .sizeThatFitsLayout){
    AmplitudeLimitPicker(conductor: TunerConductor())
}
