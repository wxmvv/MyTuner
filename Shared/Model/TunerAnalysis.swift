import Foundation

enum TunerDefaults {
    static let amplitudeLimit = 0.2
    static let pitchStandard = 440
    static let inTuneRange = 2
    static let analysisFrames = 4096
}

struct TunerSmoothing {
    private static let windowSize = 5
    private var initialPitches: [Float] = []
    private var pitchHistory: [Float] = []

    mutating func update(_ pitch: Float) -> Float? {
        let count = Self.windowSize
        if initialPitches.count < count {
            initialPitches.append(pitch)
            guard initialPitches.count == count else { return nil }
            return initialPitches.reduce(0, +) / Float(count)
        }

        pitchHistory.append(pitch)
        if pitchHistory.count > count { pitchHistory.removeFirst() }
        guard pitchHistory.count == count else { return nil }
        return pitchHistory.sorted()[count / 2]
    }
}

struct ChromaticPitch {
    let note: Note
    let cents: Float

    init?(frequency: Float, reference: Float) {
        let midi = Self.midi(frequency: frequency, reference: reference)
        let nearest = midi.rounded()
        guard let noteNumber = Int(exactly: nearest), noteNumber >= 0 else { return nil }
        note = Note(midi: noteNumber, referenceFrequency: reference)
        cents = 100 * (midi - nearest)
    }

    static func midi(frequency: Float, reference: Float) -> Float {
        69 + 12 * log2f(frequency / reference)
    }
}
