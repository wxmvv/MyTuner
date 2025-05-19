//
//  ContentView.swift
//  MyTuner
//
//  Created by wxm on 3/24/25.
//

import SwiftUI
import AVFoundation


public struct ContentView: View {
    public init() {}
    public var body: some View {
        NavigationView {
            MainView()
        }.navigationViewStyle(StackNavigationViewStyle())
    }
}

struct MainView: View {
    @State private var haveMicPermission = false
    
    var body: some View {
        List{

            Section("Permissions"){
                if haveMicPermission {
                    Text("Microphone permission granted.~ 🎉")
                        .foregroundStyle(LinearGradient(colors: [.red, .orange, .yellow, .green, .blue, .purple], startPoint: .leading, endPoint: .trailing))
                } else {
                    Button("Request microphone permission.."){
                        AVAudioSession.sharedInstance().requestRecordPermission{ granted in
                            if granted {
                                haveMicPermission = true
                            }
                        }
                    } .buttonStyle(.automatic)
                }
            }
            
            Section("Tuner Views") {
                NavigationLink("Circle Tuner", destination: CircleTunerView())
                NavigationLink("Circle Tuner in TunerView", destination: TunerView { tunerData in
                    CircleTuner(tunerData: tunerData)
                })
            }
            
            Section("Dev Tuner Views") {
                NavigationLink("Zen Tuner View", destination: ZenTunerView())
                NavigationLink("Pro Tuner View", destination: ProTunerView())
                NavigationLink("Cookbook Tuner View", destination: CookbookTunerView())
                NavigationLink("Minimal Tuner View", destination: MinimalTunerView())
            }
            
            Section("Instrument Views") {
                NavigationLink("Cookbook Instrument EXS View", destination: InstrumentEXSView())
                NavigationLink("Dev Instrument",destination: DevInstrumentView())
            }
            
            Section("Settings Views") {
                NavigationLink("List Settings", destination: ListSettingsView())
                NavigationLink("Custom Settings", destination: CustomSettingsView())
            }
            
        }
        .onAppear(){
            AVAudioSession.sharedInstance().requestRecordPermission{ granted in
                if granted {
                    print("已获取权限")
                    haveMicPermission = true
                }
            }
        }
        .navigationTitle("My Tuner")
        .navigationBarTitleDisplayMode(.inline)
    }
}


@available(iOS 17, *)
#Preview(traits: .fixedLayout(width: 500, height: 1000)){
    ContentView()
}
