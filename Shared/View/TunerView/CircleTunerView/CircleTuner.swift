//
//  CircleTunerView.swift
//  MyTuner Dev
//
//  Created by wxm on 5/3/25.
//

import SwiftUI

struct CircleTuner: View {
    var tunerData: TunerData
    @AppStorage("inTuneRange") private var inTuneRange: Int = TunerDefaults.inTuneRange
    
    var body: some View {
        GeometryReader { geo in
            if let panes = FoldPanes(geo) {
                let horizontal = panes.axis == .horizontal
                let layout = horizontal
                    ? AnyLayout(HStackLayout(spacing: panes.spacing))
                    : AnyLayout(VStackLayout(spacing: panes.spacing))
                let useBefore = horizontal
                    ? panes.before.width >= panes.after.width
                    : panes.before.height >= min(180, panes.after.height)

                layout {
                    pane(size: panes.before, showsDial: useBefore)
                    pane(size: panes.after, showsDial: !useBefore)
                }
            } else {
                dial(size: geo.size)
            }
        }
    }

    @ViewBuilder
    private func pane(size: CGSize, showsDial: Bool) -> some View {
        if showsDial {
            dial(size: size).clipped()
        } else {
            Color.clear.frame(width: size.width, height: size.height)
        }
    }

    private func dial(size: CGSize) -> some View {
        let diameter = min(180, size.width, size.height)
        let travel = max(0, (size.width - diameter) / 2 - 12)
        let arrowOffset = max(0, size.width / 2 - 20)
        let offset = getOffsetX()
        let color = getColor(cents: tunerData.cents)
        let glow = offset == 0 ? color : Color.clear

        return ZStack(alignment: .center) {
            Circle() // 背景
                .fill(Color(uiColor: .systemGray5).opacity(0.5))
                .frame(width: diameter, height: diameter)
            Circle() // 指针
                .fill(color.opacity(0.9))
                .frame(width: diameter, height: diameter)
                .offset(x: CGFloat(offset / 50) * travel)
                .animation(.easeInOut, value: tunerData.cents)
            Image(systemName: "arrowtriangle.left.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundColor(Color.primary.opacity(offset == 50 ? 0.9 : 0))
                .offset(x: arrowOffset)
                .animation(.easeInOut, value: offset)
            Image(systemName: "arrowtriangle.right.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundColor(Color.primary.opacity(offset == -50 ? 0.9 : 0))
                .offset(x: -arrowOffset)
                .animation(.easeInOut, value: offset)
            MatchedNote(note: tunerData.targetNote)
                .scaleEffect(diameter / 180)
                .frame(width: diameter, height: diameter)
                .transaction { $0.animation = nil }
        }
        .frame(width: size.width, height: size.height)
        .shadow(color: glow, radius: offset == 0 ? 100 : 0)
        .shadow(color: glow, radius: offset == 0 ? 160 : 0)
    }

    private func getOffsetX()->Float{
        abs(tunerData.cents) > Float(inTuneRange) ? min(50, max(-50, tunerData.cents)) : 0
    }
    private func getColor(cents: Float)->Color{
        // Color(red: 1, green: 1, blue: 0 ,opacity: 1) // 黄
        // Color(red: 1, green: 0, blue: 0 ,opacity: 1) // 红
        // Color(red: 0, green: 1, blue: 0 ,opacity: 1) // 绿
        // 将cents映射到色相值（红色=0°，黄色=60°，绿色=120°）
        // 红色=15° 绿色=80°
        let cents = abs(cents)
        let clampedCents = min(max(cents, 0), 50.0)
        let hue = Double(80 - (clampedCents / 50.0 * 65)) / 360.0
        return Color(hue: hue, saturation: 0.97, brightness: 1)
    }
        
}

@available(iOS 17, *)
#Preview(traits: .fixedLayout(width: 500, height: 500)){
    CircleTuner(tunerData: TunerData(cents: -50))
        .preferredColorScheme(.light)
}
@available(iOS 17, *)
#Preview(traits: .fixedLayout(width: 500, height: 500)){
    CircleTuner(tunerData: TunerData(cents: 0))
        .preferredColorScheme(.dark)
}
