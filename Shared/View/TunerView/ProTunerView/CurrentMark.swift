//
//  CurrentMark.swift
//  MyTuner
//
//  Created by wxm on 4/12/25.
//

import SwiftUI

struct CurrentMark: View {
    var tunerData: TunerData
    
    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .center, spacing: 0) {
                Text("\(String(format: "%.1f¢", tunerData.cents))")
                    .font(.system(size: 8, design: .rounded))
                    .foregroundColor(.black)
                    .padding(2)
                    .background(
                        Color.init(cgColor: CGColor(red: 235, green: 253, blue: 0, alpha: 1))
                    )
                    .cornerRadius(3)
                Rectangle()
                    .fill(
                        Color.init(cgColor: CGColor(red: 235, green: 253, blue: 0, alpha: 1))
                    )
                    .frame(width: 2, height: geo.size.height - 10)
            }
            .offset(x: (geo.size.width / 2) * CGFloat(Float(tunerData.cents) / 50),y: -23)
            .frame(width: geo.size.width,height: geo.size.height+20)
            .animation(.easeInOut, value: tunerData.cents)
        }
    }
}

@available(iOS 17, *)
#Preview(traits: .fixedLayout(width: 200, height: 100)){
    CurrentMark(tunerData: TunerData(cents: -20))
}
