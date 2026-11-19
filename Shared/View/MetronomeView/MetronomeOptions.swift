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

    var body: some View {
        NavigationStack {
            Form {
                Section("Time signature") {
                    Stepper(value: $settings.numerator, in: MetronomeSettings.beatRange) {
                        LabeledContent("Beats per measure") {
                            Text(settings.numerator, format: .number)
                        }
                    }
                    Picker("Beat unit", selection: $settings.denominator) {
                        ForEach(MetronomeSettings.denominators, id: \.self) { unit in
                            Text(verbatim: "1/\(unit)").tag(unit)
                        }
                    }
                }
                Section("Common meters") {
                    HStack(spacing: 6) {
                        ForEach([ [2,4], [3,4], [4,4], [6,8] ], id: \.self) { pair in
                            Button {
                                var updated = settings
                                updated.numerator = pair[0]
                                updated.denominator = pair[1]
                                settings = updated
                                dismiss()
                            } label: {
                                Text(verbatim: "\(pair[0])/\(pair[1])")
                                    .frame(maxWidth: .infinity, minHeight: 44)
                            }
                            .buttonStyle(.borderless)
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
}
