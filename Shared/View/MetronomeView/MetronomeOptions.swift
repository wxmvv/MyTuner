import SwiftUI

struct MetronomeDisplaySettings: View {
    @AppStorage("metronomeCircleFlash") private var circleFlash = true
    @AppStorage("metronomeScreenFlash") private var screenFlash = false
    @AppStorage("metronomeKeepAwake") private var keepAwake = false
    @AppStorage("metronomeShowBeatCount") private var showBeatCount = false

    var body: some View {
        Section("Metronome display") {
            Toggle("Flash beat circles", isOn: $circleFlash)
            Toggle("Flash the full screen", isOn: $screenFlash)
            Toggle("Keep screen awake", isOn: $keepAwake)
            Toggle("Show beat count", isOn: $showBeatCount)
        }
        .tint(Color(uiColor: .systemGreen))
    }
}

struct PracticeRecordView: View {
    @ObservedObject var metronome: MetronomePlayer

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Practice record").font(.subheadline.weight(.semibold))
                Spacer()
                Button(action: metronome.resetRecords) {
                    Label("Reset practice record", systemImage: "arrow.counterclockwise")
                        .labelStyle(.iconOnly)
                        .frame(minWidth: 44, minHeight: 44)
                }
                .disabled(metronome.totalBeats == 0 && metronome.totalMeasures == 0)
            }
            HStack(alignment: .top, spacing: 16) {
                counter("Completed measures", metronome.totalMeasures)
                counter("Total beats", metronome.totalBeats)
            }
        }
        .padding(.horizontal, 15)
        .padding(.bottom, 14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func counter(_ title: LocalizedStringKey, _ value: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value, format: .number).font(.title3.monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

struct MeterSheet: View {
    @Binding var settings: MetronomeSettings
    @Environment(\.dismiss) private var dismiss
    @ScaledMetric private var cellWidth: CGFloat = 66

    private struct Meter: Hashable {
        var numerator: Int
        var denominator: Int
        var label: String { "\(numerator)/\(denominator)" }

        init(_ numerator: Int, _ denominator: Int) {
            self.numerator = numerator
            self.denominator = denominator
        }
    }

    private let common = [
        Meter(2, 4), Meter(3, 4), Meter(4, 4), Meter(2, 2),
        Meter(3, 8), Meter(6, 8), Meter(9, 8), Meter(12, 8)
    ]

    private var current: Meter { Meter(settings.numerator, settings.denominator) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Common meters") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: cellWidth))], spacing: 8) {
                        ForEach(common, id: \.self) { meter in
                            Button { apply(meter) } label: {
                                Text(verbatim: meter.label)
                                    .font(.headline.monospacedDigit())
                                    .frame(maxWidth: .infinity, minHeight: 44)
                                    .background(.primary.opacity(current == meter ? 0.12 : 0.04),
                                                in: RoundedRectangle(cornerRadius: 10))
                                    .overlay {
                                        if current == meter {
                                            RoundedRectangle(cornerRadius: 10).strokeBorder(.primary, lineWidth: 1.5)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(current == meter ? .isSelected : [])
                        }
                    }
                }
                Section {
                    NavigationLink {
                        CustomMeter(meter: current, apply: apply)
                    } label: {
                        HStack {
                            Text("Custom meter")
                            Spacer()
                            if !common.contains(current) {
                                Text(verbatim: current.label).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .accessibilityLabel("Custom meter")
                    .accessibilityValue(Text(verbatim: common.contains(current) ? "" : current.label))
                }
            }
            .navigationTitle("Meter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }

    private func apply(_ meter: Meter) {
        var updated = settings
        updated.numerator = meter.numerator
        updated.denominator = meter.denominator
        settings = updated
        dismiss()
    }

    private struct CustomMeter: View {
        @State var meter: Meter
        var apply: (Meter) -> Void

        var body: some View {
            Form {
                Stepper(value: $meter.numerator, in: MetronomeSettings.beatRange) {
                    LabeledContent("Beats per measure") { Text(meter.numerator, format: .number) }
                }
                Picker("Beat unit", selection: $meter.denominator) {
                    ForEach(MetronomeSettings.denominators, id: \.self) { unit in
                        Text(verbatim: "1/\(unit)").tag(unit)
                    }
                }
            }
            .navigationTitle("Custom meter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { apply(meter) } }
            }
        }
    }
}
