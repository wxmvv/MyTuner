import SwiftUI
import WatchKit

struct WatchMetronomeView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject var practice: WatchPractice
    @ObservedObject var player: MetronomePlayer
    let isSelected: Bool
    @AppStorage("watchDownbeatHaptics") private var downbeatHaptics = false
    @AppStorage("watchWristDownAudio") private var wristDownAudio = false
    @AppStorage("watchCrownAdjustsTempo") private var crownAdjustsTempo = false
    @FocusState private var tempoFocused: Bool
    @State private var sheet: Sheet?

    private enum Sheet: Int, Identifiable {
        case tempo, meter
        var id: Self { self }
    }

    private let beatColor = Color(red: 1, green: 0.77, blue: 0.37)
    private var meter: WatchMeter {
        WatchMeter(beats: player.settings.numerator, unit: player.settings.denominator)
    }

    var body: some View {
        VStack(spacing: 4) {
            beatSurface
                .frame(maxHeight: .infinity)

            if let error = practice.error {
                Text(error)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 6) {
                if crownAdjustsTempo {
                    tempoControl
                        .focusable()
                        .focused($tempoFocused)
                        .digitalCrownRotation(
                            Binding(get: { Double(player.settings.tempo) }, set: { player.settings.tempo = Int($0.rounded()) }),
                            from: Double(MetronomeSettings.tempoRange.lowerBound),
                            through: Double(MetronomeSettings.tempoRange.upperBound),
                            by: 1
                        )
                } else {
                    tempoControl
                }

                Button {
                    sheet = .meter
                } label: {
                    Text(verbatim: meter.label)
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .watchGlass(in: Capsule(), interactive: true)
                        .contentShape(Capsule())
                }
                .accessibilityLabel("Time signature")
                .accessibilityValue(meter.label)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 6)
        .padding(.bottom, 7)
        .offset(y: 14)
        .onAppear {
            let updated = meter.applying(to: player.settings)
            if updated != player.settings { player.settings = updated }
        }
        .onChange(of: isSelected, initial: true) { updateTempoFocus() }
        .onChange(of: sheet) { updateTempoFocus() }
        .onChange(of: player.totalBeats) {
            guard downbeatHaptics, scenePhase == .active, player.isPlaying, player.currentBeat == 1 else { return }
            WKInterfaceDevice.current().play(.click)
        }
        .sheet(item: $sheet) { page in
            switch page {
            case .tempo:
                Form {
                    Stepper(value: $player.settings.tempo, in: MetronomeSettings.tempoRange) {
                        Text("\(player.settings.tempo) BPM")
                            .font(.body.monospacedDigit())
                    }
                    Toggle("Adjust BPM with Digital Crown", isOn: $crownAdjustsTempo)
                }
            case .meter:
                meterSettings
            }
        }
    }

    private func updateTempoFocus() {
        tempoFocused = isSelected && sheet == nil && crownAdjustsTempo
    }

    private var tempoControl: some View {
        Text("\(player.settings.tempo) BPM")
            .font(.caption.weight(.semibold).monospacedDigit())
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .frame(maxWidth: .infinity, minHeight: 44)
            .watchGlass(in: Capsule(), interactive: true)
            .contentShape(Rectangle())
            .onTapGesture { sheet = .tempo }
            .accessibilityLabel("Tempo")
            .accessibilityValue("\(player.settings.tempo) BPM")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { sheet = .tempo }
            .accessibilityAdjustableAction { direction in
                let range = MetronomeSettings.tempoRange
                switch direction {
                case .increment: player.settings.tempo = min(range.upperBound, player.settings.tempo + 1)
                case .decrement: player.settings.tempo = max(range.lowerBound, player.settings.tempo - 1)
                @unknown default: break
                }
            }
    }

    private var beatSurface: some View {
        Button {
            if practice.activity != nil {
                practice.stop()
            } else {
                practice.start(.metronome(backgroundAudio: wristDownAudio))
            }
        } label: {
            GeometryReader { geometry in
                let groupSize = meter.isCompound ? 3 : player.settings.numerator
                let groups = (player.settings.numerator + groupSize - 1) / groupSize
                let height = max(16, min(geometry.size.height * 0.64, 62))
                HStack(spacing: 6) {
                    ForEach(0..<groups, id: \.self) { group in
                        HStack(spacing: 3) {
                            let start = group * groupSize
                            ForEach(start..<min(start + groupSize, player.settings.numerator), id: \.self) { beat in
                                beatBlock(at: beat, maximumHeight: height)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay {
                    if !player.isPlaying {
                        Image(systemName: "play.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 43, height: 43)
                            .watchGlass(in: Circle(), interactive: true)
                            .transition(.opacity)
                    }
                }
                .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: player.isPlaying)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(practice.activity == nil ? "Start metronome" : "Stop metronome")
        .accessibilityValue(meter.label)
    }

    private func beatBlock(at index: Int, maximumHeight: CGFloat) -> some View {
        let accent = player.settings.beats[index]
        let isCurrent = player.currentBeat == index + 1
        let height = switch accent {
        case .accent: maximumHeight
        case .secondary: maximumHeight * 0.76
        default: maximumHeight * 0.53
        }
        let idleColor = switch accent {
        case .accent: beatColor.opacity(0.40)
        case .secondary: beatColor.opacity(0.25)
        default: Color.white.opacity(0.16)
        }
        return RoundedRectangle(cornerRadius: 5)
            .fill(isCurrent ? beatColor : idleColor)
            .frame(height: height)
            .frame(maxWidth: .infinity)
    }

    private var meterSettings: some View {
        Form {
            Picker("Time signature", selection: Binding(
                get: { meter },
                set: { player.settings = $0.applying(to: player.settings) }
            )) {
                ForEach(WatchMeter.choices, id: \.self) { option in
                    Text(verbatim: option.label).tag(option)
                }
            }
            Toggle("First-beat haptics", isOn: $downbeatHaptics)
            Toggle("Wrist-down audio", isOn: $wristDownAudio)
                .disabled(practice.activity != nil)
        }
    }
}
