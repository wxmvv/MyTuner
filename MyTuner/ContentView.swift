//
//  ContentView.swift
//  MyTuner
//
//  Created by wxm on 3/24/25.
//

import SwiftUI
import AVFoundation


public struct ContentView: View {
    public var body: some View {
        CircleTunerView()
    }
}


@available(iOS 17, *)
#Preview(traits: .fixedLayout(width: 500, height: 1000)){
    ContentView()
}
