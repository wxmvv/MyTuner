//
//  InstrumentConductor.swift
//  MyTuner
//
//  Created by wxm on 4/18/25.
//

import AudioKit
import AVFoundation
import Combine
import os.log
    
/// TODO : 音色 音量不相同


var availableInstruments: [InstrumentDefinition] = defaultAvailableInstruments

class InstrumentConductor: ObservableObject, HasAudioEngine {
    let engine = AudioEngine()
    let instrument = AppleSampler()
    
    private var autoStopTimers: [MIDINoteNumber: DispatchWorkItem] = [:]
    private let log = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "InstrumentConductor") // 日志记录器
    
    @Published var instrumentIndex = 0 {
        didSet {
            let safeIndex = max(0, min(instrumentIndex, availableInstruments.count - 1))
            if safeIndex != instrumentIndex {
                print("Instrument index \(instrumentIndex) was out of bounds, corrected to \(safeIndex).")
                instrumentIndex = safeIndex
            }
            selectedInstrument = availableInstruments[safeIndex]
            loadInstrument(definition: selectedInstrument)
        }
    }
    
    @Published var selectedInstrument: InstrumentDefinition
    @Published var velocity: MIDIVelocity = 100  // 默认力度值 100
    
    func loadInstrument(definition: InstrumentDefinition) {
        print("尝试加载乐器: \(definition.displayName)")
        guard let instrumentURL = Bundle.main.url(forResource: definition.fileName,
                                                  withExtension: definition.fileExtension,
                                                  subdirectory: definition.subdirectory) else {
            print("错误：在 Bundle 中找不到乐器文件。")
            print("  文件名: \(definition.fileName)")
            print("  扩展名: \(definition.fileExtension)")
            print("  子目录: \(definition.subdirectory ?? "无")")
            return
        }

        print("找到乐器文件: \(instrumentURL.path)")
        
        do {
            //  instrument.stop() // 在加载新乐器前停止所有音符，避免潜在问题
            switch definition.fileExtension.lowercased() {
                case "sf2":
                    guard let preset = definition.sf2Preset else {
                        print("错误：SF2 文件 \(definition.fileName) 需要 preset 和 bank 信息。")
                        return
                    }
                    try instrument.loadMelodicSoundFont(url: instrumentURL, preset: preset)
                    print("成功加载 SoundFont: \(definition.displayName) , preset: \(preset)")
                case "exs":
                    try instrument.loadInstrument(url: instrumentURL)
                    print("成功加载 EXS24: \(definition.displayName)")
                default:
                    print("错误：不支持的文件扩展名 \(definition.fileExtension)")
                    return
            }
            
            DispatchQueue.main.async {
                self.selectedInstrument = definition
            }
            
        } catch {
            print("加载乐器 \(definition.displayName) 时出错: \(error)")
            // 加载失败，不更新 selectedInstrument 状态
        }
        
    }
    
    init() {
        engine.output = instrument
        self.selectedInstrument = availableInstruments[0]
        self.loadInstrument(definition: selectedInstrument)
    }
    
    func setup(velocity: MIDIVelocity,instrumentIndex: Int) {
        self.velocity = velocity
        self.instrumentIndex = instrumentIndex
    }
    
    // 播放音符
    func playNote(note: MIDINoteNumber) {
        guard engine.avEngine.isRunning else {
            print("尝试播放音符，但引擎未运行。")
            return
        }
        instrument.play(noteNumber: note, velocity: velocity, channel: 0)
        print("播放音符: \(note)")
        
        // --- 自动停止逻辑 ---
        // 1. 取消这个特定音符可能存在的旧计时器（如果用户快速重触发同一个音符）
        cancelAutoStopTimer(for: note)
        
        // 2. 如果当前乐器需要自动停止，则安排一个停止任务
        if selectedInstrument.needsAutoStop {
            let delay = selectedInstrument.autoStopDelay
            log.debug("为音符 \(note) 安排自动停止，延迟 \(delay) 秒。")
            
            // 创建一个 DispatchWorkItem，它将在延迟后执行停止操作
            let workItem = DispatchWorkItem { [weak self] in
                // 再次检查 self 是否还存在，以及这个音符的计时器是否仍然在字典中
                // (如果在延迟期间被手动停止，它会被移除)
                if let strongSelf = self, strongSelf.autoStopTimers[note] != nil {
                    strongSelf.log.debug("自动停止音符: \(note)")
                    strongSelf.instrument.stop(noteNumber: note, channel: 0)
                    strongSelf.autoStopTimers.removeValue(forKey: note) // 清理字典
                } else {
                    print("音符 \(note) 的自动停止已被取消或执行过了。")
                }
            }
            
            // 将 workItem 存储起来，以便可以取消它
            autoStopTimers[note] = workItem
            
            // 安排 workItem 在指定的延迟后在主队列执行
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
        }
        // --- 结束自动停止逻辑 ---

    }
    
    // 停止音符 (手动触发)
    func stopNote(note: MIDINoteNumber) {
        log.debug("手动停止音符: \(note)")
        
        // --- 自动停止逻辑 ---
        // 1. 取消这个音符上任何待处理的自动停止计时器
        cancelAutoStopTimer(for: note)
        // --- 结束自动停止逻辑 ---
        
        instrument.stop(noteNumber: note, channel: 0)
    }
    
    // 辅助函数：取消指定音符的自动停止计时器
    private func cancelAutoStopTimer(for note: MIDINoteNumber) {
        if let existingTimer = autoStopTimers.removeValue(forKey: note) { // 尝试移除并获取
            log.debug("取消音符 \(note) 的待处理自动停止任务。")
            existingTimer.cancel() // 取消任务
        }
    }
    
    // 辅助函数：取消所有自动停止计时器（例如，切换乐器时调用）
    private func cancelAllAutoStopTimers() {
        log.debug("取消所有待处理的自动停止任务。")
        autoStopTimers.values.forEach { $0.cancel() } // 取消所有任务
        autoStopTimers.removeAll() // 清空字典
    }
    
    // 确保在 Conductor 销毁时停止引擎（可选但推荐）
    deinit {
        log.info("InstrumentConductor deinit - 停止引擎。")
        engine.stop()
        cancelAllAutoStopTimers() // 清理所有定时器
    }

}
