//
//  MyTunerApp.swift
//  MyTuner
//
//  Created by wxm on 3/24/25.
//

import AudioKit
import AVFoundation
import SwiftUI

@main
struct MyTunerApp: App {
    @AppStorage("responseSpeed") private var responseSpeed = ResponseSpeed.short
    @State private var audioSessionReady = false
    init() {
#if os(iOS)
        // https://www.audiokit.io/AudioKit/documentation/audiokit/settings
        Settings.bufferLength = responseSpeed.bufferLength
        Settings.enableLogging = true
        Settings.fixTruncatedRecordings = true
        Settings.sampleRate = 44_100

        if #available(iOS 18.0, *) {
            if !ProcessInfo.processInfo.isMacCatalystApp && !ProcessInfo.processInfo.isiOSAppOnMac {
                // Set samplerRate for iOS 18 and newer
                Settings.sampleRate = 48_000
            }
        }
        if #available(macOS 15.0, *) {
            // Set samplerRate for macOS 15 and newer
            Settings.sampleRate = 48_000
        }
#endif
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if audioSessionReady {
                    ContentView()
                } else {
                    ProgressView()
                }
            }
            .task {
                guard !audioSessionReady else { return }
#if os(iOS)
                let bufferDuration = Settings.bufferLength.duration
                await Task.detached(priority: .userInitiated) {
                    do {
                        let session = AVAudioSession.sharedInstance()
                        try session.setPreferredIOBufferDuration(bufferDuration)
                        try session.setCategory(.playAndRecord,
                                                options: [.defaultToSpeaker, .mixWithOthers, .allowBluetoothA2DP])
                        try session.setActive(true)
                    } catch {
                        print("Audio session setup failed: \(error)")
                    }
                }.value
#endif
                audioSessionReady = true
            }
        }
    }
}
