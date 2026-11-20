import AVFoundation
import SwiftUI

struct MetronomeView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var metronome = MetronomePlayer()
    @StateObject private var presets = MetronomePresetLibrary()
    @AppStorage("metronomeCircleFlash") private var circleFlash = true
    @AppStorage(ScreenFlashMode.storageKey) private var screenFlashMode = ScreenFlashMode.legacyDefault
    @AppStorage("metronomeKeepAwake") private var keepAwake = false
    @AppStorage("metronomeShowBeatCount") private var showBeatCount = false
    @State private var originalIdleSetting: Bool?
    @State private var sheet: Sheet?
    @State private var showingPresetMenu = false
    @State private var nextPresetAction: PresetAction?
    @ScaledMetric(relativeTo: .body) private var menuRowHeight: CGFloat = 46
    @State private var savingSong = false
    @State private var songName = ""
    @State private var saveError: String?

    private enum PresetAction { case save, manage }

    private enum Sheet: Int, Identifiable {
        case presets, meter
        var id: Self { self }
    }

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let landscape = size.width > size.height && size.width >= 540
            let compact = size.height < (landscape ? 420 : 630)
            if landscape {
                let columnGap: CGFloat = compact ? 28 : 48
                let width = min(size.width - 40, 960)
                let rhythmWidth = (width - columnGap) * 0.55
                HStack(spacing: columnGap) {
                    beatDisplay(width: rhythmWidth, gap: compact ? 6 : 10)
                        .frame(width: rhythmWidth)
                        .overlay(alignment: .top) {
                            songHeading(lines: compact ? 1 : 2)
                                .padding(.bottom, compact ? 6 : 16)
                                .alignmentGuide(.top) { $0[.bottom] }
                        }
                    ViewThatFits(in: .vertical) {
                        practiceControls(compact: compact)
                        ScrollView { practiceControls(compact: compact) }
                    }
                }
                .frame(width: width)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                let width = max(0, min(size.width - 40, 490))
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    rhythmPanel(width: width, compact: compact)
                    Spacer(minLength: compact ? 10 : 32)
                    practiceControls(compact: compact)
                }
                .frame(width: width)
                .padding(.vertical, compact ? 8 : 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background {
            let flashColor = self.flashColor
            let canAnimateFlash = !reduceMotion && metronome.isPlaying && screenFlashMode != .off
            let flashAnimation = Animation.easeOut(duration: flashColor == nil ? 0.11 : 0.04)
            ZStack {
                Color(uiColor: .systemBackground)
                if let flashColor {
                    flashColor.opacity(colorScheme == .dark ? 0.42 : 0.50)
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .animation(canAnimateFlash ? flashAnimation : nil, value: flashColor)
            .ignoresSafeArea()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                presetMenu
                    .accessibilityValue(Text(verbatim: presets.currentName(for: metronome.settings) ?? ""))
            }
        }
        .sheet(item: $sheet) { item in
            switch item {
            case .presets:
                MetronomePresetsView(settings: $metronome.settings, library: presets)
                    .presentationBackground(Material.regular)
            case .meter:
                MeterSheet(settings: $metronome.settings)
                    .presentationDetents([.medium, .large])
            }
        }
        .alert("Save song", isPresented: $savingSong) {
            TextField("Song name", text: $songName)
            Button("Cancel", role: .cancel) {}
            Button("Save") { saveCurrentSong() }
                .disabled(songName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .alert("Song presets", isPresented: Binding(get: { saveError != nil }, set: { if !$0 { saveError = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(verbatim: saveError ?? "")
        }
        .onAppear { updateIdleTimer() }
        .onChange(of: keepAwake) { _ in updateIdleTimer() }
        .onChange(of: scenePhase) { phase in
            if phase == .background { metronome.stop() }
            updateIdleTimer()
        }
        .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)) { note in
            if let type = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
               type == AVAudioSession.InterruptionType.began.rawValue { metronome.stop() }
        }
        .onDisappear {
            metronome.stop()
            restoreIdleTimer()
        }
    }

    private var flashColor: Color? {
        guard let accent = metronome.flashingAccent else { return nil }
        switch screenFlashMode {
        case .off: return nil
        case .firstBeat: return metronome.currentBeat == 1 ? .green : nil
        case .accent: return accent == .accent ? accent.color(in: colorScheme) : nil
        }
    }

    private func rhythmPanel(width: CGFloat, compact: Bool) -> some View {
        VStack(spacing: compact ? 6 : 16) {
            songHeading(lines: compact ? 1 : 2)
            beatDisplay(width: width, gap: compact ? 6 : 10)
        }
    }

    private func practiceControls(compact: Bool) -> some View {
        VStack(spacing: compact ? 8 : 12) {
            if showBeatCount { PracticeRecordView(metronome: metronome) }
            tempoControl(compact: compact)
            quickControls
            playbackButton
            if let message = metronome.errorMessage {
                Text(message).font(.footnote).foregroundStyle(.red)
            }
        }
    }

    private func songHeading(lines: Int) -> some View {
        let name = presets.currentName(for: metronome.settings)
        // Reserve a stable heading height above the beat lights, including at larger text sizes.
        return Text(verbatim: " ")
            .font(.headline)
            .lineLimit(lines, reservesSpace: true)
            .fixedSize(horizontal: false, vertical: true)
            .hidden()
            .frame(maxWidth: .infinity)
            .overlay(alignment: .bottom) {
                if let name {
                    Text(verbatim: name)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .lineLimit(lines)
                        .accessibilityAddTraits(.isHeader)
                        .id(name)
                        .transition(.opacity)
                }
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.22), value: name)
    }

    @ViewBuilder
    private var presetMenu: some View {
        if usesSystemPresetMenu {
            Menu {
                ForEach(presets.presets) { preset in
                    Button {
                        selectPreset(preset)
                    } label: {
                        if isCurrentPreset(preset) {
                            Label { Text(verbatim: preset.name) } icon: { Image(systemName: "checkmark") }
                        } else {
                            Text(verbatim: preset.name)
                        }
                    }
                }
                if !presets.presets.isEmpty { Divider() }
                Button {
                    performPresetAction(.save)
                } label: {
                    Label("Save song", systemImage: "plus")
                }
                Button {
                    performPresetAction(.manage)
                } label: {
                    Label("Manage", systemImage: "music.note.list")
                }
            } label: {
                presetMenuLabel
            }
            .menuOrder(.fixed)
        } else {
            presetPopover
        }
    }

    private var usesSystemPresetMenu: Bool {
        #if targetEnvironment(macCatalyst)
        true
        #else
        ProcessInfo.processInfo.isiOSAppOnMac
        #endif
    }

    private var presetMenuLabel: some View {
        Label("Song presets", systemImage: "music.note.list")
            .labelStyle(.iconOnly)
    }

    private var presetPopover: some View {
        Button { showingPresetMenu = true } label: {
            presetMenuLabel
        }
        .popover(isPresented: $showingPresetMenu, attachmentAnchor: .rect(.bounds), arrowEdge: .top) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(presets.presets) { preset in
                        let selected = isCurrentPreset(preset)
                        Button {
                            selectPreset(preset)
                            showingPresetMenu = false
                        } label: {
                            HStack {
                                Text(verbatim: preset.name).lineLimit(2)
                                Spacer()
                                if selected { Image(systemName: "checkmark") }
                            }
                            .frame(minHeight: menuRowHeight)
                            .contentShape(Rectangle())
                        }
                        .accessibilityAddTraits(selected ? .isSelected : [])
                    }
                    if !presets.presets.isEmpty { Divider() }
                    presetActionButton("Save song", icon: "plus", action: .save)
                    presetActionButton("Manage", icon: "music.note.list", action: .manage)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
            .scrollBounceBehavior(.basedOnSize)
            .frame(width: 250, height: min(360, CGFloat(presets.presets.count + 2) * menuRowHeight + 14))
            .presentationCompactAdaptation(.popover)
            .presentationBackground(Material.regular)
            .onDisappear {
                guard let action = nextPresetAction else { return }
                nextPresetAction = nil
                performPresetAction(action)
            }
        }
    }

    private func isCurrentPreset(_ preset: MetronomePreset) -> Bool {
        presets.selectedID == preset.id && metronome.settings == preset.settings
    }

    private func selectPreset(_ preset: MetronomePreset) {
        presets.select(preset)
        metronome.settings = preset.settings
    }

    private func performPresetAction(_ action: PresetAction) {
        switch action {
        case .save:
            songName = ""
            savingSong = true
        case .manage:
            sheet = .presets
        }
    }

    private func presetActionButton(_ title: LocalizedStringKey, icon: String, action: PresetAction) -> some View {
        Button {
            nextPresetAction = action
            showingPresetMenu = false
        } label: {
            Label(title, systemImage: icon)
                .frame(maxWidth: .infinity, minHeight: menuRowHeight, alignment: .leading)
                .contentShape(Rectangle())
        }
    }

    private func saveCurrentSong() {
        let name = songName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let preset = MetronomePreset(name: name, settings: metronome.settings)
        do {
            try presets.save(preset)
            presets.select(preset)
        } catch {
            saveError = error.localizedDescription
        }
    }

    private func tempoControl(compact: Bool) -> some View {
        HStack(spacing: 8) {
            tempoButton(-1)
            VStack(spacing: 0) {
                HStack(spacing: 4) {
                    Text("BPM").tracking(1)
                    Image(systemName: "arrow.up.arrow.down").imageScale(.small)
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
                TempoReadout(tempo: $metronome.settings.tempo, fontSize: compact ? 42 : 54)
                Text(verbatim: metronome.settings.tempoTerm)
                    .font(.system(.subheadline, design: .serif).italic())
                    .foregroundStyle(.secondary)
            }
            tempoButton(1)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, compact ? 4 : 8)
        .practiceGlass(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func tempoButton(_ delta: Int) -> some View {
        let limit = MetronomeSettings.tempoRange
        return Button {
            metronome.settings.tempo = min(limit.upperBound, max(limit.lowerBound, metronome.settings.tempo + delta))
        } label: {
            Image(systemName: delta > 0 ? "plus" : "minus")
                .font(.headline)
                .frame(width: 46, height: 46)
                .practiceGlass(in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(delta > 0 ? Text("Increase tempo") : Text("Decrease tempo"))
        .disabled(delta > 0 ? metronome.settings.tempo >= limit.upperBound : metronome.settings.tempo <= limit.lowerBound)
    }

    private func beatDisplay(width: CGFloat, gap: CGFloat) -> some View {
        let count = metronome.settings.numerator
        let capacity = max(1, Int((width + gap) / (BeatLight.hitSize + gap)))
        let rows = (count + capacity - 1) / capacity
        let columns = (count + rows - 1) / rows
        return VStack(spacing: gap) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: gap) {
                    ForEach((row * columns)..<min(count, (row + 1) * columns), id: \.self) { index in
                        let accent = metronome.settings.beats[index]
                        let pulse = circleFlash && metronome.currentBeat == index + 1 ? metronome.flashingAccent : nil
                        Button {
                            metronome.settings.beats[index] = accent.next
                        } label: {
                            BeatLight(accent: pulse ?? accent, lit: pulse != nil)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Beat \(index + 1)")
                        .accessibilityValue(Text(LocalizedStringKey(accent.title)))
                        .accessibilityHint("Tap to change accent")
                    }
                }
            }
        }
    }

    private var quickControls: some View {
        HStack(spacing: 12) {
            Button { sheet = .meter } label: {
                controlLabel("Meter", value: Text(verbatim: "\(metronome.settings.numerator)/\(metronome.settings.denominator)"))
            }
            Menu {
                Picker("Click sound", selection: $metronome.settings.sound) {
                    ForEach(ClickSound.allCases, id: \.self) { sound in
                        Text(LocalizedStringKey(sound.title)).tag(sound)
                    }
                }
            } label: {
                controlLabel("Click sound", value: Text(LocalizedStringKey(metronome.settings.sound.title)))
            }
        }
        .buttonStyle(.plain)
    }

    private func controlLabel(_ title: LocalizedStringKey, value: Text) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.caption).foregroundStyle(.secondary)
                value.font(.headline)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.up.chevron.down").font(.caption2).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 15).padding(.vertical, 11)
        .practiceGlass(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var playbackButton: some View {
        Button {
            if metronome.isPlaying { metronome.stop() } else { metronome.start() }
        } label: {
            HStack {
                Image(systemName: metronome.isPlaying ? "stop.fill" : "play.fill")
                if metronome.isPlaying { Text("Stop") } else { Text("Start") }
            }
            .font(.headline)
            .foregroundStyle(colorScheme == .dark ? .black : .white)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(Color.primary, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func updateIdleTimer() {
        if keepAwake && scenePhase == .active {
            if originalIdleSetting == nil { originalIdleSetting = UIApplication.shared.isIdleTimerDisabled }
            UIApplication.shared.isIdleTimerDisabled = true
        } else {
            restoreIdleTimer()
        }
    }

    private func restoreIdleTimer() {
        if let originalIdleSetting {
            UIApplication.shared.isIdleTimerDisabled = originalIdleSetting
            self.originalIdleSetting = nil
        }
    }
}

private struct TempoReadout: View {
    @Binding var tempo: Int
    let fontSize: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @GestureState private var dragging = false
    @State private var lastDragStep = 0
    @State private var momentum: Task<Void, Never>?
    @State private var editing = false
    @State private var entry = ""

    private let range = MetronomeSettings.tempoRange

    var body: some View {
        Text(verbatim: String(tempo))
            .font(.system(size: fontSize, weight: .semibold, design: .rounded))
            .monospacedDigit().lineLimit(1).minimumScaleFactor(0.5)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .foregroundStyle(Color.primary.opacity(dragging ? 0.75 : 1))
            .highPriorityGesture(drag.exclusively(before: TapGesture().onEnded { beginEntry() }))
            .onChange(of: dragging) { active in
                if !active { lastDragStep = 0 }
            }
            .onDisappear { momentum?.cancel() }
            .onChange(of: scenePhase) { phase in
                if phase != .active { momentum?.cancel() }
            }
            .accessibilityLabel("Tempo")
            .accessibilityValue("\(tempo) BPM")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { beginEntry() }
            .accessibilityAdjustableAction { direction in
                momentum?.cancel()
                switch direction {
                case .increment: adjust(by: 1)
                case .decrement: adjust(by: -1)
                @unknown default: break
                }
            }
            .alert("Tempo", isPresented: $editing) {
                TextField(String(tempo), text: $entry).keyboardType(.numberPad)
                Button("Cancel", role: .cancel) {}
                Button("Done") {
                    if let value = Int(entry), range.contains(value) { tempo = value }
                }
                .disabled(!range.contains(Int(entry) ?? 0))
            } message: {
                Text(verbatim: "\(range.lowerBound)–\(range.upperBound) BPM")
            }
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 5, coordinateSpace: .global)
            .updating($dragging) { _, active, _ in active = true }
            .onChanged { value in
                momentum?.cancel()
                let height = value.translation.height
                let distance = abs(height)
                // Short drags start near 1 BPM per 8 points and gradually approach 1 per 3.
                let scaled = distance / 3 - 6 * (1 - exp(-distance / 30))
                let step = Int(scaled.rounded()) * (height < 0 ? 1 : -1)
                adjust(by: step - lastDragStep)
                lastDragStep = step
            }
            .onEnded { value in
                let remaining = value.translation.height - value.predictedEndTranslation.height
                coast(projectedDistance: remaining)
            }
    }

    private func coast(projectedDistance: CGFloat) {
        guard !reduceMotion else { return }
        let start = tempo
        let extra = Int(min(6, max(-6, projectedDistance / 28)).rounded(.towardZero))
        let target = min(range.upperBound, max(range.lowerBound, start + extra))
        guard target != start else { return }

        momentum = Task { @MainActor in
            let clock = ContinuousClock()
            let began = clock.now
            var expected = start
            // A quadratic ease-out spaces the last few BPM changes farther apart.
            for frame in 1...12 {
                do { try await clock.sleep(until: began + .milliseconds(frame * 16)) }
                catch { return }
                guard !Task.isCancelled, tempo == expected else { return }
                let remaining = 1 - Double(frame) / 12
                let offset = Double(target - start) * (1 - remaining * remaining)
                let next = start + Int(offset.rounded())
                if next != expected { tempo = next }
                expected = next
            }
        }
    }

    private func adjust(by delta: Int) {
        let value = min(range.upperBound, max(range.lowerBound, tempo + delta))
        if value != tempo { tempo = value }
    }

    private func beginEntry() {
        momentum?.cancel()
        entry = ""
        editing = true
    }
}

private extension BeatAccent {
    var lightDiameter: CGFloat {
        switch self {
        case .accent: return 32
        case .secondary: return 26
        case .normal: return 20
        case .muted: return 14
        }
    }

    func color(in colorScheme: ColorScheme) -> Color {
        // The circle tuner spans hues from 15° (red-orange) to 80° (lime).
        let hue: Double
        switch self {
        case .accent: hue = 15
        case .secondary: hue = 48
        case .normal: hue = 80
        case .muted: return Color(uiColor: .systemGray)
        }
        return Color(hue: hue / 360, saturation: 0.97, brightness: colorScheme == .dark ? 1 : 0.83)
    }
}

private struct BeatLight: View {
    static let hitSize: CGFloat = 46
    let accent: BeatAccent
    let lit: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let color = accent.color(in: colorScheme)
        return Circle()
            .fill(color.opacity(lit ? 1 : 0.94))
            .frame(width: accent.lightDiameter, height: accent.lightDiameter)
            .scaleEffect(lit ? 1.18 : 1)
            .shadow(color: color.opacity(lit ? 0.95 : (accent == .muted ? 0 : 0.65)), radius: lit ? 9 : 5)
            .shadow(color: color.opacity(lit ? 0.65 : (accent == .muted ? 0 : 0.32)), radius: lit ? 16 : 10)
            .frame(width: Self.hitSize, height: Self.hitSize)
            .contentShape(Rectangle())
    }
}

private extension View {
    @ViewBuilder
    func practiceGlass<S: InsettableShape>(in shape: S) -> some View {
        if #available(iOS 26, *) {
            glassEffect(.regular.interactive(), in: shape)
        } else {
            background(.regularMaterial, in: shape)
                .overlay { shape.strokeBorder(.primary.opacity(0.12), lineWidth: 1) }
        }
    }
}
