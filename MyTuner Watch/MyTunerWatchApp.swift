import AVFoundation
import SwiftUI

@main
struct MyTunerWatchApp: App {
    var body: some Scene {
        WindowGroup { WatchPracticeView() }
    }
}

private struct WatchPracticeView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var practice = WatchPractice()
    @State private var tool = Tool.metronome

    private enum Tool {
        case metronome, tuner
    }

    var body: some View {
        TabView(selection: $tool) {
            WatchMetronomeView(practice: practice, player: practice.metronome, isSelected: tool == .metronome)
                .tag(Tool.metronome)
            WatchTunerView(practice: practice)
                .tag(Tool.tuner)
        }
        .tabViewStyle(.page)
        .onChange(of: tool) {
            practice.stop()
            if tool == .tuner { practice.resumeTunerIfAuthorized() }
        }
        .onChange(of: scenePhase) {
            practice.sceneChanged(scenePhase)
            if scenePhase == .active && tool == .tuner { practice.resumeTunerIfAuthorized() }
        }
        .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)
            .receive(on: RunLoop.main)) { notification in
            let type = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            if type == AVAudioSession.InterruptionType.began.rawValue { practice.stop() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .AVAudioEngineConfigurationChange)
            .receive(on: RunLoop.main)) { notification in
            if let engine = notification.object as? AVAudioEngine { practice.inputConfigurationChanged(engine) }
        }
        .onReceive(practice.metronome.$isPlaying.dropFirst().receive(on: RunLoop.main)) { isPlaying in
            if !isPlaying { practice.metronomeDidStop() }
        }
    }
}
