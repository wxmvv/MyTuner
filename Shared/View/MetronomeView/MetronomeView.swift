import AVFoundation
import SwiftUI

struct MetronomeView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var metronome = MetronomePlayer()
    @AppStorage("metronomeTempo") private var tempo = 120
    @AppStorage("metronomeBeats") private var beats = 4

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(tempo)").font(.system(size: 76, weight: .bold, design: .rounded))

                Text("BPM").font(.headline).foregroundStyle(.secondary)
            }
            HStack {
                Button { changeTempo(-1) } label: { Image(systemName: "minus.circle") }
                    .accessibilityLabel("Decrease tempo")
                Slider(value: Binding(get: { Double(tempo) }, set: { tempo = Int($0) }), in: 40...240, step: 1)
                    .accessibilityLabel("Tempo")
                Button { changeTempo(1) } label: { Image(systemName: "plus.circle") }
                    .accessibilityLabel("Increase tempo")
            }
            .font(.title2)
            .padding(.horizontal)

            Stepper(value: $beats, in: 1...12) {
                HStack {
                    Text("Beats per measure")
                    Spacer()
                    Text("\(beats)").foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
            HStack(spacing: 8) {
                ForEach(1...beats, id: \.self) { beat in
                    Circle().fill(metronome.currentBeat == beat ? Color.accentColor : Color.secondary.opacity(0.25))
                        .frame(width: beats > 8 ? 16 : 22, height: beats > 8 ? 16 : 22)
                        .accessibilityHidden(true)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Current beat")
            .accessibilityValue("\(metronome.currentBeat) / \(beats)")
            Button {
                if metronome.isPlaying { metronome.stop() }
                else { metronome.start(tempo: tempo, beats: beats) }
            } label: {
                Label {
                    if metronome.isPlaying { Text("Stop") } else { Text("Start") }
                } icon: {
                    Image(systemName: metronome.isPlaying ? "stop.fill" : "play.fill")
                }
                .font(.headline).frame(minWidth: 150).padding()
            }
            .buttonStyle(.borderedProminent)
            .tint(.mint)
            .foregroundStyle(.black)
            if let error = metronome.errorMessage {
                Text(error).foregroundStyle(.red)
            }
            Spacer()
        }
        .padding()
        .navigationTitle("Metronome")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            tempo = min(240, max(40, tempo))
            beats = min(12, max(1, beats))
        }
        .onChange(of: tempo) { _ in restartIfPlaying() }
        .onChange(of: beats) { _ in restartIfPlaying() }
        .onChange(of: scenePhase) { phase in if phase != .active { metronome.stop() } }
        .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)) { notification in
            if let raw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
               raw == AVAudioSession.InterruptionType.began.rawValue { metronome.stop() }
        }
        .onDisappear { metronome.stop() }
    }

    private func changeTempo(_ amount: Int) { tempo = min(240, max(40, tempo + amount)) }
    private func restartIfPlaying() {
        if metronome.isPlaying { metronome.start(tempo: tempo, beats: beats) }
    }
}
