import Accelerate
import AVFoundation

// AVAudioEngine serializes callbacks for this tap. Only the resulting pitch
// crosses to the main actor.
final class MicrophoneAnalyzer: @unchecked Sendable {
    private static let frameCount = TunerDefaults.analysisFrames
    // Watch and simulator microphone levels are lower than the iPhone input.
    private static let amplitudeLimit: Float = 0.05
    private let sampleRate: Double
    private let tracker: OpaquePointer
    private let report: @Sendable (ChromaticPitch) -> Void
    private var smoothing = TunerSmoothing()
    private var pending = Array(repeating: Float.zero, count: frameCount)
    private var pendingCount = 0

    init?(sampleRate: Double, report: @escaping @Sendable (ChromaticPitch) -> Void) {
        guard let tracker = watchPitchTrackerCreate(Int32(sampleRate), Int32(Self.frameCount)) else { return nil }
        self.sampleRate = sampleRate
        self.tracker = tracker
        self.report = report
    }

    deinit { watchPitchTrackerDestroy(tracker) }

    func consume(_ buffer: AVAudioPCMBuffer) {
        guard let channel = buffer.floatChannelData?[0], buffer.stride == 1 else { return }
        let available = Int(buffer.frameLength)

        // AudioKit's PitchTap analyzes one 4096-frame window per delivery.
        if pendingCount == 0 && available >= Self.frameCount {
            analyze(channel)
            return
        }

        let copied = min(available, Self.frameCount - pendingCount)
        pending.withUnsafeMutableBufferPointer { window in
            window.baseAddress!.advanced(by: pendingCount).update(from: channel, count: copied)
        }
        pendingCount += copied
        if pendingCount == Self.frameCount {
            pending.withUnsafeBufferPointer { analyze($0.baseAddress!) }
            pendingCount = 0
        }
    }

    private func analyze(_ samples: UnsafePointer<Float>) {
        var frequency: Float = 0
        var amplitude: Float = 0
        watchPitchTrackerAnalyze(tracker, samples, Self.frameCount, &frequency, &amplitude)
        // Like iOS, retain the last reading during silence and between valid estimates.
        guard amplitude > Self.amplitudeLimit, frequency.isFinite, frequency > 0,
              isPeriodic(samples, frequency: frequency),
              let frequency = smoothing.update(frequency),
              let reading = ChromaticPitch(frequency: frequency, reference: Float(TunerDefaults.pitchStandard))
        else { return }
        report(reading)
    }

    private func isPeriodic(_ samples: UnsafePointer<Float>, frequency: Float) -> Bool {
        let period = (sampleRate / Double(frequency)).rounded()
        guard period >= 2, period <= Double(Self.frameCount / 2) else { return false }
        let lag = Int(period)
        let count = vDSP_Length(Self.frameCount - lag)
        let shifted = samples.advanced(by: lag)
        var similarity: Float = 0
        var energy: Float = 0
        var shiftedEnergy: Float = 0
        vDSP_dotpr(samples, 1, shifted, 1, &similarity, count)
        vDSP_svesq(samples, 1, &energy, count)
        vDSP_svesq(shifted, 1, &shiftedEnergy, count)
        return similarity > 0.55 * (energy * shiftedEnergy).squareRoot()
    }
}
