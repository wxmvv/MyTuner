import AVFoundation
import SwiftUI

struct MetronomeView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var metronome = MetronomePlayer()
    @StateObject private var presets = MetronomePresetLibrary()
    @AppStorage("metronomeCircleFlash") private var circleFlash = true
    @AppStorage("metronomeScreenFlash") private var screenFlash = false
    @AppStorage("metronomeKeepAwake") private var keepAwake = false
    @State private var originalIdleSetting: Bool?
    @State private var sheet: Sheet?

    private enum Sheet: Int, Identifiable {
        case presets, meter, options
        var id: Self { self }
    }

    private var ink: Color {
        colorScheme == .dark ? Color(red: 0.56, green: 0.91, blue: 0.77) : Color(red: 0.06, green: 0.39, blue: 0.29)
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 20) {
                    presetButton
                    Spacer(minLength: 0)
                    tempoControl
                    beatDisplay(width: min(geometry.size.width - 40, 490))
                    Spacer(minLength: 0)
                    quickControls
                    playbackButton
                    if let message = metronome.errorMessage {
                        Text(message).font(.footnote).foregroundStyle(.red)
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
        .navigationTitle("Metronome")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { sheet = .options } label: {
                    Label("Practice settings", systemImage: "slider.horizontal.3")
                }
            }
        }
        .sheet(item: $sheet) { item in
            switch item {
            case .presets:
                MetronomePresetsView(settings: $metronome.settings, library: presets)
            case .meter:
                MeterSheet(settings: $metronome.settings)
                    .presentationDetents([.medium, .large])
            case .options:
                MetronomeOptions(metronome: metronome, circleFlash: $circleFlash,
                                 screenFlash: $screenFlash, keepAwake: $keepAwake)
            }
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

    private var presetButton: some View {
        Button { sheet = .presets } label: {
            HStack(spacing: 8) {
                Image(systemName: "music.note.list")
                if let name = presets.currentName(for: metronome.settings) {
                    Text(verbatim: name).lineLimit(1)
                } else {
                    Text("Song presets")
                }
                Image(systemName: "chevron.down").font(.caption2.bold())
            }
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 16)
            .frame(minHeight: 44)
            .practiceGlass(in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private var tempoControl: some View {
        VStack(spacing: 4) {
            Text("BPM")
                .font(.caption.weight(.semibold)).tracking(2)
                .foregroundStyle(.secondary)
            HStack {
                tempoButton(-1)
                Spacer(minLength: 4)
                Text(verbatim: String(metronome.settings.tempo))
                    .font(.system(size: 88, weight: .light, design: .rounded))
                    .monospacedDigit().lineLimit(1).minimumScaleFactor(0.5)
                    .accessibilityLabel("Tempo")
                    .accessibilityValue("\(metronome.settings.tempo) BPM")
                Spacer(minLength: 4)
                tempoButton(1)
            }
            Text(verbatim: metronome.settings.tempoTerm)
                .font(.system(.title3, design: .serif).italic()).foregroundStyle(ink)
            Slider(value: Binding(get: { Double(metronome.settings.tempo) },
                                  set: { metronome.settings.tempo = Int($0.rounded()) }),
                   in: Double(MetronomeSettings.tempoRange.lowerBound)...Double(MetronomeSettings.tempoRange.upperBound), step: 1)
                .tint(ink).padding(.top, 8)
                .accessibilityLabel("Tempo")
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
        let capacity = max(1, Int((width - 24) / 54))
        let rows = (count + capacity - 1) / capacity
        let columns = (count + rows - 1) / rows
        return VStack(spacing: 10) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 6) {
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
        .padding(.vertical, 12)
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

private struct BeatCircle: View {
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
        .frame(width: 46, height: 46)
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
