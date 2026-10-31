//
//  CircleTunerView.swift
//  MyTuner
//
//  Created by wxm on 5/10/25.
//

import SwiftUI
import AudioKit
import AVFoundation


struct CircleTunerView: View {
    @StateObject var conductor = TunerConductor()
    @StateObject var instrumentConductor = InstrumentConductor()
    
    @AppStorage("smoothingFactor") private var smoothingFactor: Double = 0.5
    @AppStorage("inTuneRange") private var inTuneRange: Int = 2
    @AppStorage("pitchStandard") private var pitchStandard = 440
    @AppStorage("amplitudeLimit") private var amplitudeLimit: Double = 0.2
    @AppStorage("preferredName") private var preferredName: ModifierPreference = .preferSharps
    @AppStorage("tuningMode") private var tuningMode: TuningMode = .chromatic
    @AppStorage("instrument") private var instrument: Instrument = .Acoustic
    
    @AppStorage("velocity") var velocity:Int = 100
    @AppStorage("instrumentIndex") var instrumentIndex:Int = 0
    
    @State private var showSettingsSheet = false
    @State private var showMetronome = false
    
    var body: some View {
        NavigationStack {
        AudioKitView(conductor: conductor) {
            ZStack {
                Color.white.opacity(0)
                    .edgesIgnoringSafeArea(.all)
                CircleTuner(tunerData: conductor.data)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                    // Instrument
                    MinimalInstrumentView(instrumentConductor: instrumentConductor, conductor: conductor)
                        .offset(y: tuningMode == .instrument ? 0 : 100)
                    
                }
            }
        }
        .onAppear {
            conductor.setup(amplitudeLimit: Float(amplitudeLimit), pitchStandard: Float(pitchStandard), smoothingFactor: Float(smoothingFactor), inTuneRange: inTuneRange, outOfTuneRange: 20, tuningMode: tuningMode, instrument: instrument)
            conductor.start()
            instrumentIndex = max(0, min(instrumentIndex, availableInstruments.count - 1))
            instrumentConductor.setup(velocity: MIDIVelocity(velocity), instrumentIndex: instrumentIndex)
            instrumentConductor.start()
            
        }
        .onDisappear {
            conductor.stop()
            instrumentConductor.stop()
        }
        .sheet(isPresented: $showMetronome, onDismiss: { conductor.start() }) {
            MetronomeView()
        }
        .sheet(isPresented: $showSettingsSheet) {
            ListSettingsViewSheet(conductor: conductor,instrumentConductor: instrumentConductor, showSettingsSheet: $showSettingsSheet)
                .presentationBackground(Material.regular)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                TuningModePicker(conductor: conductor, toolbarLabel: true)
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    conductor.stop()
                    showMetronome = true
                } label: {
                    Label("Metronome", systemImage: "metronome")
                }
                Button {
                    showSettingsSheet = true
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
            }
        }
        .tint(.primary)
        }
        
    }
}


@available(iOS 17, *)
#Preview(traits: .fixedLayout(width: 500, height: 1000)){
    CircleTunerView()
}


/// The click track is rendered as a repeating audio buffer, so beat timing does
/// not depend on the main thread or on the visual update timer.
private final class MetronomePlayer: ObservableObject {
    @Published var isPlaying = false
    @Published var currentBeat = 0
    @Published var errorMessage: String?

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    private var displayTimer: Timer?
    private var framesPerBeat: Double = 1
    private var beats = 4

    init() {
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
    }

    func start(tempo: Int, beats: Int) {
        stop()
        self.beats = beats
        let sampleRate = format.sampleRate
        framesPerBeat = sampleRate * 60.0 / Double(tempo)
        let frameCount = AVAudioFrameCount((framesPerBeat * Double(beats)).rounded())
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let samples = buffer.floatChannelData?[0] else {
            errorMessage = NSLocalizedString("Unable to start the metronome.", comment: "")
            return
        }
        buffer.frameLength = frameCount
        for frame in 0..<Int(frameCount) { samples[frame] = 0 }
        for beat in 0..<beats {
            let start = Int((Double(beat) * framesPerBeat).rounded())
            let frequency = beat == 0 ? 1_600.0 : 1_000.0
            for offset in 0..<min(Int(sampleRate * 0.035), Int(frameCount) - start) {
                let time = Double(offset) / sampleRate
                let envelope = exp(-time * 140.0)
                samples[start + offset] = Float(sin(2 * Double.pi * frequency * time) * envelope * 0.7)
            }
        }
        do {
            try engine.start()
            player.scheduleBuffer(buffer, at: nil, options: .loops)
            player.play()
            errorMessage = nil
            isPlaying = true
            currentBeat = 1
            displayTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [weak self] _ in
                guard let self = self, let time = self.player.lastRenderTime,
                      let position = self.player.playerTime(forNodeTime: time) else { return }
                let sample = Double(position.sampleTime).truncatingRemainder(dividingBy: Double(frameCount))
                self.currentBeat = min(self.beats, Int(sample / self.framesPerBeat) + 1)
            }
        } catch {
            stop()
            errorMessage = NSLocalizedString("Unable to start the metronome.", comment: "")
        }
    }

    func stop() {
        displayTimer?.invalidate()
        displayTimer = nil
        player.stop()
        engine.stop()
        isPlaying = false
        currentBeat = 0
    }
}

private struct MetronomeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var metronome = MetronomePlayer()
    @AppStorage("metronomeTempo") private var tempo = 120
    @AppStorage("metronomeBeats") private var beats = 4

    var body: some View {
        NavigationStack {
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
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { dismiss() } } }
        }
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
