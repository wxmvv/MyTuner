//
//  NoteTicks.swift
//  MyTuner
//
//  Created by wxm on 3/28/25.
//

import SwiftUI

struct NoteTicks: View {
    let tunerData:TunerData
    
    var body: some View {
        NoteDistanceMarkers()
            .overlay(
                CurrentNoteMarker(
                    frequency: tunerData.pitch,
                    cents: tunerData.cents,
                    showRangeMark: false
                )
            )
    }
}

@available(iOS 17, *)
#Preview(traits: .sizeThatFitsLayout){
    NoteTicks(tunerData: TunerData())
}
