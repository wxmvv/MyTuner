//
//  CurrentNoteMarker.swift
//  MyTuner
//
//  Created by wxm on 3/27/25.
//

import SwiftUI

struct CurrentNoteMarker: View {
    
    @AppStorage("inTuneRange") private var inTuneRange = 2

    let frequency:Float
    let cents: Float
    var showRangeMark = false
    
    var body: some View {
        GeometryReader { geometry in
            if showRangeMark {
                VStack(alignment: .center) {
                    Rectangle()
                        .frame(width: 4, height: NoteTickSize.medium.height)
                        .cornerRadius(4)
                        .foregroundColor(.primary.opacity(0.7))
                }
                .frame(width: geometry.size.width,height: geometry.size.height)
                .offset(
                    x: (geometry.size.width / 2) * CGFloat(Float(inTuneRange) / 50)
                )
                
                VStack(alignment: .center) {
                    Rectangle()
                        .frame(width: 4, height: NoteTickSize.medium.height)
                        .cornerRadius(4)
                        .foregroundColor(.primary.opacity(0.7))
                }
                .frame(width: geometry.size.width,height: geometry.size.height)
                .offset(
                    x: (geometry.size.width / 2) * CGFloat(-Float(inTuneRange) / 50)
                )
            }
            
            VStack(alignment: .center) {
                Rectangle()
                    .frame(width: 4, height: NoteTickSize.large.height)
                    .cornerRadius(4)
                    .foregroundColor(
                        abs(cents) <= Float(inTuneRange) ? .imperceptibleMusicalDistance : abs(cents) <= Float(20) ? .perceptibleMediumMusicalDistance : .perceptibleLargeMusicalDistance
                    )
            }
            .frame(width: geometry.size.width)
            .offset(
                x: (geometry.size.width / 2) * CGFloat(cents / 50)
            )
            .animation(.easeInOut, value: cents)
        }
    }
}

@available(iOS 17, *)
#Preview(traits: .sizeThatFitsLayout){
    CurrentNoteMarker(frequency: 440.0,cents: 0,showRangeMark: true)
}
