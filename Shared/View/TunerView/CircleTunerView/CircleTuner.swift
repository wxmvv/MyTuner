//
//  CircleTunerView.swift
//  MyTuner Dev
//
//  Created by wxm on 5/3/25.
//

import SwiftUI

struct CircleTuner: View {
    var tunerData: TunerData
    @AppStorage("inTuneRange") private var inTuneRange: Int = 2
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .center) {
                Circle() // 背景
                    .fill(Color(uiColor: .systemGray5).opacity(0.5))
                    .frame(width: 180,height: 180)
                Circle() // 指针
                    .fill(getColor(cents: tunerData.cents).opacity(0.9))
                    .frame(width: 180,height: 180)
                    .offset(x: CGFloat(getOffsetX()) * geo.size.width/100,y: 0)
                    .animation(.easeInOut, value: tunerData.cents)
                // ArrowMark right
                Image(systemName: "arrowtriangle.left.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundColor(Color.primary.opacity(getOffsetX() == 50 ? 0.9 : 0))
                    .offset(x: geo.size.width/2 - 20, y: 0)
                    .animation(.easeInOut, value: getOffsetX())
                // ArrowMark left
                Image(systemName: "arrowtriangle.right.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundColor(Color.primary.opacity(getOffsetX() == -50 ? 0.9 : 0))
                    .offset(x: -geo.size.width/2 + 20, y: 0)
                    .animation(.easeInOut, value: getOffsetX())
                MatchedNote(note: tunerData.targetNote)
                    .frame(width: 180,height: 180)
                    .animation(.none,value: tunerData.cents)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .shadow(color: getOffsetX()==0 ? getColor(cents:tunerData.cents).opacity(1): Color.clear, radius: getOffsetX()==0 ? 100 : 0, x: 0, y: 0)
            .shadow(color: getOffsetX()==0 ? getColor(cents:tunerData.cents).opacity(1): Color.clear, radius: getOffsetX()==0 ? 160 : 0, x: 0, y: 0)
            .animation(.easeInOut, value: tunerData.cents)
        }
    }
    private func getOffsetX()->Float{
        abs(tunerData.cents) > Float(inTuneRange) ? abs(tunerData.cents) > 50 ? 50 : tunerData.cents  : 0
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
