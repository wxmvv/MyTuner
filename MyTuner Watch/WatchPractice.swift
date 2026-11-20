import AVFoundation
import Combine
import Foundation
import os
import SwiftUI

@MainActor
final class WatchPractice: ObservableObject {
    enum Activity: Equatable {
        case metronome(backgroundAudio: Bool)
        case tuner
    }

    let metronome = MetronomePlayer()
    @Published private(set) var activity: Activity?
    @Published private(set) var isPreparing = false
    @Published private(set) var pitch: ChromaticPitch?
    @Published private(set) var error: LocalizedStringKey?

    var hasMicrophonePermission: Bool { AVAudioApplication.shared.recordPermission == .granted }

    private let log = Logger(subsystem: "cc.wxmvv.MyTuner.watchkitapp", category: "Audio")
    private let audioSession = AVAudioSession.sharedInstance()
    private var audioTask: Task<Void, Never>?
    private var inputEngine: AVAudioEngine?
    private var sessionActive = false
    private var request = 0

    func resumeTunerIfAuthorized() {
        guard activity == nil, hasMicrophonePermission else { return }
        log.notice("Starting the tuner with existing microphone permission")
        start(.tuner)
    }

    func start(_ activity: Activity) {
        stop()
        self.activity = activity
        error = nil
        isPreparing = true
        let request = self.request
        let previous = audioTask

        // Let an in-flight activation finish deactivating before changing category.
        audioTask = Task { [weak self] in
            await previous?.value
            guard let self, !Task.isCancelled else { return }
            await self.prepare(activity, request: request)
        }
    }

    func stop() {
        request += 1
        audioTask?.cancel()
        if let inputEngine {
            inputEngine.stop()
            inputEngine.inputNode.removeTap(onBus: 0)
            self.inputEngine = nil
        }
        if metronome.isPlaying { metronome.stop() }
        if sessionActive {
            try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            sessionActive = false
        }
        activity = nil
        isPreparing = false
        pitch = nil
        error = nil
    }

    func sceneChanged(_ phase: ScenePhase) {
        switch activity {
        case .metronome(backgroundAudio: false):
            if phase == .background { stop() }
        case .tuner:
            if phase == .background { stop() }
        default:
            break
        }
    }

    func metronomeDidStop() {
        guard case .metronome = activity, !isPreparing, !metronome.isPlaying else { return }
        stop()
    }

    func inputConfigurationChanged(_ engine: AVAudioEngine) {
        if engine === inputEngine && !engine.isRunning { stop() }
    }

    private func prepare(_ activity: Activity, request: Int) async {
        do {
            switch activity {
            case let .metronome(backgroundAudio):
                try audioSession.setCategory(.playback, mode: .default,
                                             policy: backgroundAudio ? .longFormAudio : .default)
            case .tuner:
                if !hasMicrophonePermission {
                    guard await AVAudioApplication.requestRecordPermission() else {
                        if request == self.request { fail("Allow microphone access in Settings.") }
                        return
                    }
                }
                guard !Task.isCancelled else { return }
                try audioSession.setCategory(.playAndRecord, mode: .measurement)
            }

            if case .tuner = activity {
                try await Task.detached(priority: .userInitiated) {
                    try AVAudioSession.sharedInstance().setActive(true)
                }.value
            } else {
                guard try await audioSession.activate() else { throw AudioFailure.activation }
            }
            guard !Task.isCancelled else {
                try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
                return
            }
            sessionActive = true

            switch activity {
            case .metronome:
                metronome.start()
                guard metronome.isPlaying else { throw AudioFailure.engine }
            case .tuner:
                try startMicrophone(request: request)
            }
            isPreparing = false
        } catch {
            guard request == self.request else { return }
            let failure = error as NSError
            log.error("Audio startup failed: \(failure.domain, privacy: .public) (\(failure.code))")
            switch (activity, error as? AudioFailure) {
            case (.metronome(backgroundAudio: true), _):
                fail("Audio could not start. Connect headphones or turn off wrist-down audio.")
            case (.metronome, _):
                fail("Unable to play the metronome.")
            case (.tuner, .noMicrophoneInput):
#if targetEnvironment(simulator)
                fail("The Watch simulator did not provide microphone input.")
#else
                fail("No microphone input is available. Try again after disconnecting Bluetooth audio.")
#endif
            case (.tuner, _):
                fail("Unable to start the microphone.")
            }
        }
    }

    private func startMicrophone(request: Int) throws {
        let engine = AVAudioEngine()
        let input = engine.inputNode
        let hardwareFormat = input.inputFormat(forBus: 0)
        let format = input.outputFormat(forBus: 0)
        guard hardwareFormat.sampleRate > 0, hardwareFormat.channelCount > 0,
              format.sampleRate >= 8_000, format.channelCount > 0 else {
            log.error("Invalid microphone format: hardware \(hardwareFormat.sampleRate) Hz, tap \(format.sampleRate) Hz")
            throw AudioFailure.noMicrophoneInput
        }
        guard let analyzer = MicrophoneAnalyzer(sampleRate: format.sampleRate, report: { [weak self] reading in
            DispatchQueue.main.async {
                guard let self, request == self.request else { return }
                if self.pitch == nil { self.log.info("First microphone pitch reading received") }
                self.pitch = reading
            }
        }) else { throw AudioFailure.engine }
        input.installTap(onBus: 0, bufferSize: AVAudioFrameCount(TunerDefaults.analysisFrames), format: format) { buffer, _ in
            analyzer.consume(buffer)
        }
        inputEngine = engine
        try engine.start()
        log.info("Microphone started at \(format.sampleRate) Hz")
    }

    private func fail(_ message: LocalizedStringKey) {
        stop()
        error = message
    }

    private enum AudioFailure: Error { case activation, engine, noMicrophoneInput }
}
