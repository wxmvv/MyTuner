import AVFoundation
import SwiftUI

struct MetronomeView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var metronome = MetronomePlayer()
    @StateObject private var presets = MetronomePresetLibrary()
    @AppStorage("metronomeCircleFlash") private var circleFlash = true
    @AppStorage("metronomeScreenFlash") private var screenFlash = false
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

    private var ink: Color {
        colorScheme == .dark ? Color(red: 0.56, green: 0.91, blue: 0.77) : Color(red: 0.06, green: 0.39, blue: 0.29)
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    VStack(spacing: 16) {
                        songHeading
                        VStack(spacing: 24) {
                            beatDisplay(width: min(geometry.size.width - 40, 490))
                            tempoControl
                        }
                    }
                    Spacer(minLength: 32)
                    VStack(spacing: 12) {
                        if showBeatCount { PracticeRecordView(metronome: metronome) }
                        quickControls
                        playbackButton
                        if let message = metronome.errorMessage {
                            Text(message).font(.footnote).foregroundStyle(.red)
                        }
                    }
                }
                .frame(maxWidth: 490)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, minHeight: geometry.size.height)
            }
        }
        .background {
            ZStack {
                Color(uiColor: .systemBackground)
                RadialGradient(colors: [ink.opacity(0.12), .clear], center: .center,
                               startRadius: 0, endRadius: 390)
                if screenFlash && metronome.isFlashing {
                    ink.opacity(colorScheme == .dark ? 0.22 : 0.16)
                }
            }
            .ignoresSafeArea()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                presetMenu
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

    private var songHeading: some View {
        let name = presets.currentName(for: metronome.settings)
        // Size the space above BPM independently of the song, including at larger text sizes.
        return Text(verbatim: " ")
            .font(.headline)
            .lineLimit(2, reservesSpace: true)
            .fixedSize(horizontal: false, vertical: true)
            .hidden()
            .frame(maxWidth: .infinity)
            .overlay(alignment: .bottom) {
                if let name {
                    Text(verbatim: name)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .accessibilityAddTraits(.isHeader)
                        .id(name)
                        .transition(.opacity)
                }
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.22), value: name)
    }

    private var presetMenu: some View {
        Button { showingPresetMenu = true } label: {
            Label("Song presets", systemImage: "music.note.list")
                .labelStyle(.iconOnly)
        }
        .accessibilityValue(Text(verbatim: presets.currentName(for: metronome.settings) ?? ""))
        .popover(isPresented: $showingPresetMenu, attachmentAnchor: .rect(.bounds), arrowEdge: .top) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(presets.presets) { preset in
                        let selected = presets.selectedID == preset.id && metronome.settings == preset.settings
                        Button {
                            presets.select(preset)
                            metronome.settings = preset.settings
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
                switch nextPresetAction {
                case .save:
                    songName = ""
                    savingSong = true
                case .manage:
                    sheet = .presets
                case nil:
                    break
                }
                nextPresetAction = nil
            }
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

    private var tempoControl: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Text("BPM").tracking(2)
                Image(systemName: "arrow.up.arrow.down").imageScale(.small)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)
            HStack {
                tempoButton(-1)
                TempoReadout(tempo: $metronome.settings.tempo, ink: ink)
                tempoButton(1)
            }
            Text(verbatim: metronome.settings.tempoTerm)
                .font(.system(.title3, design: .serif).italic()).foregroundStyle(ink)
        }
        .padding(.horizontal, 8)
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

    private func beatDisplay(width: CGFloat) -> some View {
        let count = metronome.settings.numerator
        let gap: CGFloat = 10
        let capacity = max(1, Int((width + gap) / (BeatCircle.diameter + gap)))
        let rows = (count + capacity - 1) / capacity
        let columns = (count + rows - 1) / rows
        return VStack(spacing: gap) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: gap) {
                    ForEach((row * columns)..<min(count, (row + 1) * columns), id: \.self) { index in
                        let accent = metronome.settings.beats[index]
                        let lit = circleFlash && metronome.currentBeat == index + 1 && metronome.isFlashing
                        Button {
                            metronome.settings.beats[index] = accent.next
                        } label: {
                            BeatCircle(accent: accent, lit: lit, ink: ink)
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
            .background(ink, in: Capsule())
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
    let ink: Color
    @GestureState private var dragging = false
    @State private var lastDragStep = 0
    @State private var editing = false
    @State private var entry = ""

    private let range = MetronomeSettings.tempoRange

    var body: some View {
        Text(verbatim: String(tempo))
            .font(.system(size: 88, weight: .light, design: .rounded))
            .monospacedDigit().lineLimit(1).minimumScaleFactor(0.5)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .foregroundStyle(dragging ? ink : .primary)
            .highPriorityGesture(drag.exclusively(before: TapGesture().onEnded { beginEntry() }))
            .onChange(of: dragging) { active in
                if !active { lastDragStep = 0 }
            }
            .accessibilityLabel("Tempo")
            .accessibilityValue("\(tempo) BPM")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { beginEntry() }
            .accessibilityAdjustableAction { direction in
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
                let step = Int((-value.translation.height / 3).rounded())
                adjust(by: step - lastDragStep)
                lastDragStep = step
            }
    }

    private func adjust(by delta: Int) {
        let value = min(range.upperBound, max(range.lowerBound, tempo + delta))
        if value != tempo { tempo = value }
    }

    private func beginEntry() {
        entry = ""
        editing = true
    }
}

private struct BeatCircle: View {
    static let diameter: CGFloat = 46
    var accent: BeatAccent
    var lit: Bool
    var ink: Color

    var body: some View {
        ZStack {
            Circle().fill(lit ? ink : ink.opacity(accent == .muted ? 0 : 0.13))
            Circle().strokeBorder(ink.opacity(lit ? 1 : 0.55),
                                  style: StrokeStyle(lineWidth: lit ? 3 : 1.4, dash: accent == .muted ? [3, 3] : []))
            Group {
                switch accent {
                case .normal: Circle().frame(width: 7, height: 7)
                case .muted: Image(systemName: "minus")
                case .accent: Image(systemName: "chevron.up")
                case .secondary: Image(systemName: "chevron.right")
                }
            }
            .font(.headline.bold())
            .foregroundStyle(lit ? Color(uiColor: .systemBackground) : ink)
        }
        .frame(width: Self.diameter, height: Self.diameter)
        .shadow(color: lit ? ink.opacity(0.38) : .clear, radius: 6)
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
