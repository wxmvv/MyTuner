import SwiftUI

struct MetronomeOptions: View {
    @ObservedObject var metronome: MetronomePlayer
    @Binding var circleFlash: Bool
    @Binding var screenFlash: Bool
    @Binding var keepAwake: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Display") {
                    Toggle("Flash beat circles", isOn: $circleFlash)
                    Toggle("Flash the full screen", isOn: $screenFlash)
                    Toggle("Keep screen awake", isOn: $keepAwake)
                }
                Section("Practice record") {
                    LabeledContent("Completed measures") { Text(metronome.totalMeasures, format: .number) }
                    LabeledContent("Total beats") { Text(metronome.totalBeats, format: .number) }
                    Button("Reset practice record", role: .destructive) { confirmReset = true }
                        .disabled(metronome.totalBeats == 0 && metronome.totalMeasures == 0)
                }
            }
            .navigationTitle("Practice settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .confirmationDialog("Reset practice record?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Reset", role: .destructive) { metronome.resetRecords() }
                Button("Cancel", role: .cancel) {}
            }
        }
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
                        LabeledContent("Custom meter") {
                            if !common.contains(current) { Text(verbatim: current.label) }
                        }
                    }
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
