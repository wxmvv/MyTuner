import AVFoundation
import Combine

/// The click track is rendered as a repeating audio buffer, so beat timing does
/// not depend on the main thread or on the visual update timer.
final class MetronomePlayer: ObservableObject {
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
