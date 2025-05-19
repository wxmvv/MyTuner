//
//  MinimalTopToolbar.swift
//  MyTuner
//
//  Created by wxm on 4/6/25.
//

import SwiftUI

struct MinimalTopToolbar: View {
    var conductor :TunerConductor
    @Binding var showSettingsSheet:Bool
    
    var body: some View {
        VStack{
            HStack {
                TuningModePicker(conductor: conductor)
                    .foregroundColor(.primary)
                Spacer()
                
                // Settings button
                Button(action: {
                    showSettingsSheet = true
                }) {
                    Image(systemName: "gearshape")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
            }
            .padding()
        }
    }
}



@available(iOS 17, *)
#Preview(traits: .sizeThatFitsLayout){
    MinimalTopToolbar(conductor: TunerConductor(), showSettingsSheet: .constant(false))
}
