import SwiftUI

struct WatchTunerView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject var practice: WatchPractice

    private var cents: Double { Double(practice.pitch?.cents ?? 0) }
    private var inTune: Bool { practice.pitch != nil && abs(cents) <= Double(TunerDefaults.inTuneRange) }
    private var canTapDial: Bool { practice.activity == nil }
    private var color: Color {
        Color(hue: (80 - min(abs(cents), 50) * 65 / 50) / 360, saturation: 0.97, brightness: 1)
    }

    var body: some View {
        VStack(spacing: 3) {
            GeometryReader { geometry in
                let diameter = min(geometry.size.width * 0.68, geometry.size.height * 0.88)
                if canTapDial {
                    Button {
                        practice.start(.tuner)
                    } label: {
                        dial(diameter: diameter, travel: 0)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(practice.hasMicrophonePermission ? "Listen" : "Allow microphone")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    dial(diameter: diameter, travel: max(0, (geometry.size.width - diameter) / 2))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .accessibilityElement(children: .combine)
                }
            }

            status
                .font(.caption2.weight(.medium))
                .foregroundStyle(inTune ? color : .secondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .padding(.horizontal, 9)
                .padding(.bottom, 9)
        }
    }

    private func dial(diameter: CGFloat, travel: CGFloat) -> some View {
        ZStack {
            if canTapDial {
                Circle().fill(.clear)
                    .watchGlass(in: Circle(), interactive: true)
            } else {
                Circle().fill(.white.opacity(0.12))
            }

            if practice.pitch != nil {
                Circle()
                    .fill(color.opacity(0.94))
                    .shadow(color: inTune ? color.opacity(0.7) : .clear, radius: 18)
                    .offset(x: inTune ? 0 : (cents / 50) * travel)
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: cents)
            }

            if let pitch = practice.pitch {
                HStack(alignment: .firstTextBaseline, spacing: 1) {
                    Text(verbatim: pitch.note.noteNameString)
                        .font(.system(size: diameter * 0.43, weight: .medium, design: .rounded))
                    Text(verbatim: "\(pitch.note.octave)")
                        .font(.system(size: diameter * 0.19, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.black)
                .shadow(color: color.opacity(0.8), radius: 2)
            } else if practice.isPreparing {
                ProgressView().tint(.white)
            } else {
                Image(systemName: canTapDial ? "mic.fill" : "tuningfork")
                    .font(.system(size: diameter * 0.25, weight: .medium))
                    .foregroundStyle(.white.opacity(canTapDial ? 0.9 : 0.38))
            }
        }
        .frame(width: diameter, height: diameter)
        .contentShape(Circle())
    }

    @ViewBuilder
    private var status: some View {
        if let error = practice.error {
            Text(error)
        } else if let pitch = practice.pitch {
            if inTune {
                Text("In tune")
            } else {
                let offset = abs(Int(pitch.cents.rounded()))
                if pitch.cents < 0 {
                    Text("\(offset) cents flat")
                } else {
                    Text("\(offset) cents sharp")
                }
            }
        } else if practice.isPreparing {
            Text("Starting microphone…")
        } else if practice.activity == .tuner {
            Text("Play a note")
        } else if practice.hasMicrophonePermission {
            Text("Listen")
        } else {
            Text("Allow microphone")
        }
    }
}
