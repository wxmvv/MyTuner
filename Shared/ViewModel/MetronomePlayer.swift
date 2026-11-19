import AVFoundation
import Combine
import os

/// Only fixed-size values cross the audio thread boundary. The render callback
/// can always finish the current block if the UI is busy editing the settings.
private struct Rhythm {
    let tempo: Int
    let numerator: Int
    let denominator: Int
    let soundOffset: Int
    let accents: UInt32

    init(_ settings: MetronomeSettings) {
        tempo = settings.tempo
        numerator = settings.numerator
        denominator = settings.denominator
        switch settings.sound {
        case .click: soundOffset = 0
        case .wood: soundOffset = 4
        case .bell: soundOffset = 8
        }
        accents = settings.beats.enumerated().reduce(0) { packed, beat in
            let value: UInt32
            switch beat.element {
            case .muted: value = 0
            case .normal: value = 1
            case .secondary: value = 2
            case .accent: value = 3
            }
            return packed | (value << (2 * beat.offset))
        }
    }

    func clickIndex(at beat: Int) -> Int {
        soundOffset + Int((accents >> (2 * beat)) & 3)
    }
}

private struct Playhead {
    var beat = 0
    var flashing = false
    var beats = 0
    var measures = 0
}

private final class ClickTrack {
    static let sampleRate = 44_100.0

    private let requested: OSAllocatedUnfairLock<Rhythm>
    private let displayed = OSAllocatedUnfairLock(initialState: Playhead())
    private let clicks: [[Float]]

    // Accessed exclusively by the audio callback while the engine is running.
    private var rhythm: Rhythm
    private var head = Playhead()
    private var frame: Int64 = 0
    private var nextBeatFrame = 0.0
    private var beatStart: Int64 = 0
    private var clickIndex = 0

    init(settings: MetronomeSettings) {
        rhythm = Rhythm(settings)
        requested = OSAllocatedUnfairLock(initialState: rhythm)
        clicks = [ClickSound.click, .wood, .bell].flatMap { sound in
            (0...3).map { Self.makeClick(sound: sound, level: $0) }
        }
    }

    func update(_ settings: MetronomeSettings) {
        let next = Rhythm(settings)
        requested.withLock { $0 = next }
    }

    var position: Playhead { displayed.withLock { $0 } }

    func render(count: Int, into destination: UnsafeMutablePointer<Float>) {
        let pending = requested.withLockIfAvailable { $0 } ?? rhythm
        destination.update(repeating: 0, count: count)
        var offset = 0
        while offset < count {
            if frame >= Int64(nextBeatFrame.rounded()) {
                let meterChanged = rhythm.numerator != pending.numerator || rhythm.denominator != pending.denominator
                if head.beat == rhythm.numerator { head.measures += 1 }
                head.beat = meterChanged ? 1 : head.beat % pending.numerator + 1
                rhythm = pending
                clickIndex = rhythm.clickIndex(at: head.beat - 1)
                head.beats += 1
                beatStart = frame
                nextBeatFrame += Self.sampleRate * 60 / Double(rhythm.tempo)
            }
            let length = min(count - offset, Int(Int64(nextBeatFrame.rounded()) - frame))
            let clickOffset = Int(frame - beatStart)
            let remaining = clicks[clickIndex].count - clickOffset
            if remaining > 0 {
                clicks[clickIndex].withUnsafeBufferPointer { click in
                    destination.advanced(by: offset).update(from: click.baseAddress!.advanced(by: clickOffset),
                                                            count: min(length, remaining))
                }
            }
            frame += Int64(length)
            offset += length
        }
        let flashDuration = min(Self.sampleRate * 0.09, (nextBeatFrame - Double(beatStart)) * 0.35)
        head.flashing = Double(frame - beatStart) < flashDuration
        _ = displayed.withLockIfAvailable { $0 = head }
    }

    private static func makeClick(sound: ClickSound, level: Int) -> [Float] {
        guard level > 0 else { return [] }
        let pitch = [0, 0.84, 1.08, 1.38][level]
        let gain = [0, 0.48, 0.65, 0.83][level]
        let length = Int(sampleRate * (sound == .bell ? 0.17 : 0.07))
        return (0..<length).map { frame in
            let t = Double(frame) / sampleRate
            let phase = 2 * Double.pi * t * pitch
            let tone: Double
            switch sound {
            case .click:
                tone = sin(phase * 1690) * exp(-t * 180)
            case .wood:
                tone = 0.7 * sin(phase * 760) * exp(-t * 93)
                     + 0.3 * sin(phase * 1825) * exp(-t * 170)
            case .bell:
                tone = 0.55 * sin(phase * 1250) * exp(-t * 35)
                     + 0.3 * sin(phase * 2615) * exp(-t * 58)
                     + 0.15 * sin(phase * 3475) * exp(-t * 70)
            }
            let attack = min(1, t / 0.0005)
            let release = min(1, Double(length - 1 - frame) / (sampleRate * 0.003))
            return Float(tone * gain * attack * release)
        }
    }
}

final class MetronomePlayer: ObservableObject {
    @Published var settings: MetronomeSettings {
        didSet {
            guard settings != oldValue else { return }
            settings.save(to: defaults)
            track?.update(settings)
        }
    }
    @Published private(set) var isPlaying = false
    @Published private(set) var currentBeat = 0
    @Published private(set) var isFlashing = false
    @Published private(set) var totalBeats: Int
    @Published private(set) var totalMeasures: Int
    @Published private(set) var errorMessage: String?

    private let defaults: UserDefaults
    private var engine: AVAudioEngine?
    private var track: ClickTrack?
    private var displayTimer: Timer?
    private var configurationObserver: AnyCancellable?
    private var recorded = Playhead()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        settings = .load(from: defaults)
        totalBeats = defaults.integer(forKey: "metronomeTotalBeats")
        totalMeasures = defaults.integer(forKey: "metronomeTotalMeasures")
    }

    func start() {
        guard !isPlaying else { return }
        let engine = AVAudioEngine()
        let track = ClickTrack(settings: settings)
        let format = AVAudioFormat(standardFormatWithSampleRate: ClickTrack.sampleRate, channels: 1)!
        let source = AVAudioSourceNode(format: format) { _, _, frameCount, output in
            let buffers = UnsafeMutableAudioBufferListPointer(output)
            guard let samples = buffers.first?.mData?.assumingMemoryBound(to: Float.self) else { return noErr }
            track.render(count: Int(frameCount), into: samples)
            return noErr
        }
        engine.attach(source)
        engine.connect(source, to: engine.mainMixerNode, format: format)
        do {
            try engine.start()
        } catch {
            errorMessage = NSLocalizedString("Unable to start the metronome.", comment: "")
            return
        }
        self.engine = engine
        self.track = track
        recorded = Playhead()
        isPlaying = true
        errorMessage = nil
        configurationObserver = NotificationCenter.default.publisher(for: .AVAudioEngineConfigurationChange, object: engine)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                if self?.engine?.isRunning == false { self?.stop() }
            }
        let timer = Timer(timeInterval: 1.0 / 60, repeats: true) { [weak self] _ in self?.refresh() }
        RunLoop.main.add(timer, forMode: .common)
        displayTimer = timer
        refresh()
    }

    func stop() {
        displayTimer?.invalidate()
        displayTimer = nil
        configurationObserver = nil
        engine?.stop()
        refresh()
        engine = nil
        track = nil
        isPlaying = false
        currentBeat = 0
        isFlashing = false
    }

    func resetRecords() {
        refresh()
        totalBeats = 0
        totalMeasures = 0
        saveRecords()
    }

    private func refresh() {
        guard let head = track?.position else { return }
        if currentBeat != head.beat { currentBeat = head.beat }
        if isFlashing != head.flashing { isFlashing = head.flashing }
        guard recorded.beats != head.beats || recorded.measures != head.measures else { return }
        totalBeats += head.beats - recorded.beats
        totalMeasures += head.measures - recorded.measures
        recorded = head
        saveRecords()
    }

    private func saveRecords() {
        defaults.set(totalBeats, forKey: "metronomeTotalBeats")
        defaults.set(totalMeasures, forKey: "metronomeTotalMeasures")
    }

    deinit { displayTimer?.invalidate() }
}
