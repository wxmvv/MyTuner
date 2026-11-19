import AudioKit
import Combine
import Foundation
import os.log

final class InstrumentConductor: ObservableObject, HasAudioEngine {
    let engine = AudioEngine()
    private let instrument = AppleSampler()
    private let bankURL = Bundle.main.url(forResource: "Reference Instruments",
                                          withExtension: "sf2", subdirectory: "Sampler")
    private let log = Logger(subsystem: Bundle.main.bundleIdentifier ?? "MyTuner", category: "ReferenceTone")

    @Published var velocity: MIDIVelocity = 100
    @Published var instrumentIndex = 0 {
        didSet { loadSelectedInstrument() }
    }

    private var loadedInstrument: InstrumentDefinition?
    private var soundingNote: MIDINoteNumber?

    init() {
        engine.output = instrument
    }

    func setup(velocity: MIDIVelocity, instrumentIndex: Int) {
        self.velocity = velocity
        self.instrumentIndex = instrumentIndex
    }

    private func loadSelectedInstrument() {
        let selection = InstrumentDefinition.atStoredIndex(instrumentIndex)
        guard selection != loadedInstrument else { return }
        releaseNote()
        guard let bankURL else {
            log.error("Reference sound bank missing")
            return
        }
        do {
            try instrument.loadMelodicSoundFont(url: bankURL, preset: selection.rawValue)
            loadedInstrument = selection
        } catch {
            loadedInstrument = nil
            log.error("Could not load reference instrument: \(error.localizedDescription)")
        }
    }

    func playNote(note: MIDINoteNumber, pitchStandard: Int = 440) {
        guard engine.avEngine.isRunning, pitchStandard > 0 else { return }
        if loadedInstrument == nil { loadSelectedInstrument() }
        guard loadedInstrument != nil else { return }

        releaseNote()
        instrument.tuning = 12 * log2(Float(pitchStandard) / 440)
        instrument.play(noteNumber: note, velocity: velocity)
        soundingNote = note
    }

    private func releaseNote() {
        if let soundingNote {
            instrument.stop(noteNumber: soundingNote)
            self.soundingNote = nil
        }
    }

    func stop() {
        releaseNote()
        engine.stop()
        instrument.resetSampler()
    }

    deinit { engine.stop() }
}
