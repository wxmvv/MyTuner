//
//  MarkDistance.swift
//  MyTuner
//
//  Created by wxm on 4/11/25.
//

import SwiftUI

struct MarkDistance: View {
    var inTuneCents : Float = 5
    
    var body: some View {
        VStack(alignment: .center, spacing: 2) {
            // 刻度线
            HStack(spacing: 2) {
                ForEach(-21...21, id: \.self) { tick in
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.primary.opacity(0.5))
                        .frame(width: 1, height: tick % 4 == 0 ? 20 : 14)
                        .ExpandingRectangle()
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .overlay(alignment: .center) {
                GeometryReader { geometry in
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.primary.opacity(0.7), lineWidth: 1)
                        .frame(width: CGFloat(inTuneCents)/50 * geometry.size.width ,height: 22)
                        .background(Material.thin)
                        .frame(maxWidth: .infinity,maxHeight: .infinity, alignment: .center)
                }
            }
            
            
            // 数字标签
            HStack(spacing: 2) {
                ForEach(-21...21, id: \.self) { tick in
                    if tick % 4 == 0 {
                        let text =  tick == 0 ? " 0" : tick > 0 ? "+\(tick / 4 * 10)" : "\(tick / 4 * 10)"
                        if abs(Float(tick / 4 * 10)) < inTuneCents {
                            Text(text)
                                .font(.system(size: 3))
                                .foregroundColor(.clear)
                                .frame(width: 8, height: 6, alignment: .center) // 确保宽度足够，居中对齐
                        } else {
                            Text(text)
                                .font(.system(size: 3))
                                .frame(width: 8, height: 6, alignment: .center) // 确保宽度足够，居中对齐
                        }
            
                    } else {
                        Spacer()
                            .ExpandingRectangle()
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}

extension View {
    func ExpandingRectangle() -> some View {
        ZStack {
            Rectangle()
                .foregroundColor(.clear)
            self
        }
    }
}



@available(iOS 17, *)
#Preview(traits: .fixedLayout(width: 300, height: 100)){
    MarkDistance(inTuneCents: 8)
}


