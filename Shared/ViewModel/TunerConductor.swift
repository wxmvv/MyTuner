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
    @Published var amplitudeLimit:Float = 0.15
    @Published var pitchStandard: Float = 440.0 // { didSet {} }
    @Published var inTuneRange: Int = 2
    @Published var outOfTuneRange: Int = 20
    @Published var tuningMode: TuningMode = .chromatic // { didSet {} }
    @Published var instrument: Instrument = .Acoustic
    
    private let noteNamesWithSharps = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]
    private let noteNamesWithFlats = ["C", "D♭", "D", "E♭", "E", "F", "G♭", "G", "A♭", "A", "B♭", "B"]
    let engine = AudioEngine()
    let initialDevice: Device
    let mic: AudioEngine.InputNode
    let tappableNodeA: Fader
    let tappableNodeB: Fader
    let tappableNodeC: Fader
    let silence: Fader
    var tracker: PitchTap!
    
    // [EMA]
    @Published var smoothingFactor: Float = 0.7  // [EMA] 调整平滑程度 [0,1] 越大则越平滑，越小则越灵敏
    private var smoothedPitch: Float = 0.0  // [EMA]
    // 取前 n 个样本然后取平均值
    var initialPitches : [Float] = []
    let initialSamplesToAverage = 3
    func resetSmoothing() {
        // 当检测到声音停止或长时间静音时，可能需要重置状态
        smoothedPitch = 0.0
        initialPitches.removeAll()
        print("Smoothing reset.")
    }
    // 取中位数
    var pitchHistory: [Float] = []
    let medianWindowSize = 3 // 使用最近3个pitch值的中位数
    // 通过动态调整 smoothFactor 来平滑
    let initialSmoothingFactor: Float = 0.7 // 初始阶段，更快响应
    let stableSmoothingFactor: Float = 0.95 // 稳定阶段，更强平滑
    var sampleCount: Int = 0
    let transitionSampleCount: Int = 3 // 多少个样本后切换到稳定平滑因子
    

    
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
        
        tracker = PitchTap(mic) { pitch, amp in
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
        return 69.0 + 12.0 * log2f(pitch / pitchStandard)
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
        data.amplitude = amp
        
        // [EMA] 平滑 https://zh.wikipedia.org/wiki/移動平均#指數移動平均
        if smoothedPitch == 0.0 {
            if initialPitches.count < initialSamplesToAverage {
                initialPitches.append(pitch)
                print("Collecting initial samples: \(initialPitches.count)/\(initialSamplesToAverage)")
                
                if initialPitches.count == initialSamplesToAverage {
                    let sum = initialPitches.reduce(0, +) // 计算初始平均值
                    smoothedPitch = sum / Float(initialSamplesToAverage)
                    print("Initial smoothed pitch set to average: \(smoothedPitch)")
                }

            }
        } else {
            smoothedPitch = smoothingFactor * smoothedPitch + (1.0 - smoothingFactor) * pitch
        }

        if smoothedPitch == 0.0 {
            return
        }
        
        // 计算中位数
        pitchHistory.append(pitch)
        if pitchHistory.count > medianWindowSize {
            pitchHistory.removeFirst() // 保持窗口大小
        }
        // 至少需要足够的数据点才能计算中位数
        guard pitchHistory.count == medianWindowSize else {
            // 在窗口填满前，可以用原始值或不做处理
            if smoothedPitch == 0.0 { smoothedPitch = pitch } // 简单处理
            print("Collecting history for median: \(pitchHistory.count)/\(medianWindowSize)")
            return
        }
        let sortedPitches = pitchHistory.sorted()
        smoothedPitch = sortedPitches[medianWindowSize / 2] // 对于奇数窗口大小
        
        
        data.pitch = smoothedPitch
        
        
        // 处理信息
        let midi = pitchToMidi(smoothedPitch)
        
        if tuningMode == .chromatic {
            let nearestMidi = round(midi)
            let cents = 100.0 * (midi - Float(nearestMidi))
            let targetNote = Note(midi: Int(nearestMidi),referenceFrequency: pitchStandard)
            let targetFrequency = pitchStandard * powf(2.0, (Float(nearestMidi) - 69.0) / 12.0)
            
            data.cents = cents
            data.isPitchHigh = cents > 0.0
            data.targetMidi = Int(nearestMidi)
            data.targetNote = targetNote
            data.targetFrequency = targetFrequency
            data.frequencyDistance = pitch - targetFrequency
            let noteIndex = Int(nearestMidi) % 12
            let octave = Int(nearestMidi / 12) - 1
            data.noteNameWithSharps = "\(noteNamesWithSharps[noteIndex])\(octave)"
            data.noteNameWithFlats = "\(noteNamesWithFlats[noteIndex])\(octave)"
            
        } else if tuningMode == .instrument {
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
