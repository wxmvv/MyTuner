//
//  TunerConductor.swift
//  MyTuner
//
//  Created by wxm on 3/26/25.
//

import AudioKit
import AudioKitEX
import AudioToolbox
import SoundpipeAudioKit
import SwiftUI

// TODO 可选择输入设备 InputDevica
// TODO micSensitivity 麦克灵敏度 !

struct TunerData {
    var pitch: Float = 0.0
    var rawPitch: Float = 0.0
    var amplitude: Float = 0.0
    var noteNameWithSharps = "-"
    var noteNameWithFlats = "-"
    var cents: Float = 0.0
    var isPitchHigh: Bool = false
    var targetMidi: Int = 0
    var targetNote: Note = Note(midi: 69)
    var targetFrequency: Float = 0.0
    var frequencyDistance: Float = 0.0
}

class TunerConductor: ObservableObject, HasAudioEngine {
    @Published var data : TunerData = TunerData()
    @Published var amplitudeLimit:Float = 0.075
    @Published var pitchStandard: Float = 440.0 // { didSet {} }
    @Published var inTuneRange: Int = 2
    @Published var outOfTuneRange: Int = 20
    @Published var tuningMode: TuningMode = .chromatic // { didSet {} }
    @Published var instrument: Instrument = .Acoustic
    
    let engine = AudioEngine()
    let initialDevice: Device
    let mic: AudioEngine.InputNode
    let tappableNodeA: Fader
    let tappableNodeB: Fader
    let tappableNodeC: Fader
    let silence: Fader
    var tracker: PitchTap!
    
    @Published var smoothingFactor: Float = 0.5
    private var smoothing = TunerSmoothing()

    init() {
        guard let input = engine.input else { fatalError() }
        guard let device = engine.inputDevice else { fatalError() }
        initialDevice = device
        mic = input
        
        tappableNodeA = Fader(mic)
        tappableNodeB = Fader(tappableNodeA)
        tappableNodeC = Fader(tappableNodeB)
        silence = Fader(tappableNodeC, gain: 0)
        engine.output = silence
        
        tracker = PitchTap(mic, bufferSize: UInt32(TunerDefaults.analysisFrames)) { pitch, amp in
            DispatchQueue.main.async {
                self.update(pitch[0], amp[0])
            }
        }
        tracker.start()
    }
    
    func setup(amplitudeLimit:Float, pitchStandard: Float, smoothingFactor: Float, inTuneRange: Int, outOfTuneRange: Int, tuningMode: TuningMode, instrument: Instrument) {
        self.amplitudeLimit = amplitudeLimit
        self.pitchStandard = pitchStandard
        self.smoothingFactor = smoothingFactor
        self.inTuneRange = inTuneRange
        self.outOfTuneRange = outOfTuneRange
        self.tuningMode = tuningMode
        self.instrument = instrument
    }
    
    
    // 转换为midi编号
    func pitchToMidi(_ pitch: Float) -> Float {
        ChromaticPitch.midi(frequency: pitch, reference: pitchStandard)
    }
    
    // Instrument模式使用
    func findNearestMidi(midi: Float, from instrumentMidis: [Int]) -> Int? {
        guard !instrumentMidis.isEmpty else { return nil }
        let nearestMidi = instrumentMidis.reduce(instrumentMidis[0]) { (currentNearest, nextMidi) in
            let currentDistance = abs(Float(currentNearest) - midi)
            let nextDistance = abs(Float(nextMidi) - midi)
            return currentDistance < nextDistance ? currentNearest : nextMidi
        }
        return nearestMidi
    }
    
    // Helper computed properties for tuning guidance
    var isInTune: Bool {
        abs(data.cents) < Float(inTuneRange)
    }
    
    var isOutOfTune:Bool {
        abs(data.cents) > Float(outOfTuneRange)
    }
    



    func update(_ pitch: AUValue, _ amp: AUValue) {
        guard amp > amplitudeLimit else { return } // Reduces sensitivity to background noise to prevent random / fluctuating data.
        guard pitch > 0 else { return }  // 可以选择在这里重置 smoothedPitch 或维持旧值  // smoothedPitch = 0.0 // 如果希望静音时重置
        
        data.pitch = pitch
        data.rawPitch = pitch
        data.amplitude = amp
        
        
        guard let smoothedPitch = smoothing.update(pitch) else { return }

        // 最终pitch
        data.pitch = smoothedPitch
        
        // 将pitch处理为midi信息
        if tuningMode == .chromatic {
            guard let reading = ChromaticPitch(frequency: smoothedPitch, reference: pitchStandard) else { return }
            let targetNote = reading.note
            data.cents = reading.cents
            data.isPitchHigh = reading.cents > 0
            data.targetMidi = targetNote.midi
            data.targetNote = targetNote
            data.targetFrequency = targetNote.frequency
            data.frequencyDistance = pitch - targetNote.frequency
            data.noteNameWithSharps = "\(targetNote.noteName.noteNameWithSharps)\(targetNote.octave)"
            data.noteNameWithFlats = "\(targetNote.noteName.noteNameWithFlats)\(targetNote.octave)"
        } else if tuningMode == .instrument {
            let midi = pitchToMidi(smoothedPitch)
            let nearestMidi = findNearestMidi(midi: midi, from: instrument.midis())
            let cents = 100.0 * (midi - Float(nearestMidi!))
            let targetNote = Note(midi: nearestMidi!,referenceFrequency: pitchStandard)
            let targetFrequency = targetNote.frequency
            
            if cents > 50 { data.cents = 50.0 }
            else if cents < -50 { data.cents = -50.0 }
            else { data.cents = cents }
            data.isPitchHigh = cents > 0.0
            data.targetMidi = nearestMidi!
            data.targetNote = targetNote
            data.targetFrequency = targetFrequency
            data.frequencyDistance = pitch - targetFrequency
            data.noteNameWithSharps = "\(targetNote.noteName.noteNameWithSharps)\(targetNote.octave)"
            data.noteNameWithFlats = "\(targetNote.noteName.noteNameWithFlats)\(targetNote.octave)"
        }
    }
}
