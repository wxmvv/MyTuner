//
//  DevInstrumentView.swift
//  MyTuner
//
//  Created by wxm on 4/18/25.
//

import SwiftUI
import AudioKit

struct DevInstrumentView: View {
    @StateObject var conductor = InstrumentConductor()
    @AppStorage("velocity") var velocity = 60
    @AppStorage("instrumentIndex") var instrumentIndex = 0
    
    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 4)
    
    var body: some View {
        VStack{
            List {
                
                Picker("velocity", selection: $velocity) {
                    ForEach(0...127, id: \.self) { i in
                        Text(String(i))
                            .tag(i)
                    }
                }
                .onChange(of: velocity) { newValue in
                    velocity = newValue
                    conductor.velocity = MIDIVelocity(newValue)
                }
                
                Picker("instrument", selection: $instrumentIndex ) {
                    ForEach(0 ..< availableInstruments.count, id: \.self) { i in
                        Text(availableInstruments[i].displayName)
                            .tag(i)
                    }
                }
                .onChange(of: instrumentIndex) { newValue in
                    instrumentIndex = newValue
                    conductor.instrumentIndex = newValue
                }
                
                
            }
            LazyVGrid(columns: columns, spacing: 15) {
                ForEach(32...64,id: \.self) { i in
                    Button{
                        conductor.playNote(note: MIDINoteNumber(i))
                    } label: {
                        Text("\(Note(midi: i).noteName):\(Note(midi: i).octave)")
                    }
                }
                
            }
        }
        .onAppear{
            conductor.velocity = MIDIVelocity(velocity)
            let safeIndex = max(0, min(instrumentIndex, availableInstruments.count - 1))
            conductor.instrumentIndex = safeIndex
            instrumentIndex = safeIndex
            conductor.start()
        }
        .onDisappear{
            conductor.stop()
        }
       
    }
}

#Preview {
    DevInstrumentView()
}
