//
//  ArcTunerView.swift
//  MyTuner
//
//  Created by wxm on 4/7/25.
//

import SwiftUI

struct ArcTunerView: View {
    
    var conductor: TunerConductor
    
    private let startAngle: Double = -150
    private let endAngle: Double = -30
    
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let dialSize = min(width, height) * 0.8 // 表盘大小按屏幕较小边长的80%
            let scale = dialSize / 300 // 缩放比例（原始设计基于300的表盘大小）
            
            
            VStack(alignment: .center) {
                ZStack{
                    
                        // 半圆形表盘背景
                    Circle()
                        .trim(from: 0, to: 0.5) // 只显示上半部分
                        .stroke(Color.primary, lineWidth: 2 * scale)
                        .frame(width: dialSize, height: dialSize)
                        .rotationEffect(.degrees(180)) // 旋转使开口朝下
                    
                        // 刻度线和标签
                    ForEach(-50...50, id: \.self) { value in
                        if value % 10 == 0 { // 每20个单位显示一个刻度和标签
                                             // 刻度线
                            Rectangle()
                                .frame(width: 2 * scale, height: value % 40 == 0 ? 20 * scale : 10 * scale) // 大刻度和小刻度
                                .foregroundColor(.primary)
                                .offset(y: -dialSize * 0.5) // 刻度线位置（130/300）
                                .rotationEffect(.degrees(Double(value) * 1.8)) // 每个刻度旋转角度
                            
                                // 标签
                            Text("\(value)")
                                .font(.system(size: 12 * scale))
                                .offset(y: -dialSize * 0.58) // 标签位置（100/300）
                                .rotationEffect(.degrees(Double(value) * 1.8))
                        }
                    }
                }
            }.frame(
                width: geo.size.width,
                height: geo.size.height
            )
            
        }
    }
}



@available(iOS 17, *)
#Preview(traits: .fixedLayout(width: 500, height: 1000)){
    ArcTunerView(conductor: TunerConductor())
}
