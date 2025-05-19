//
//  NeumorphicButton.swift
//  MyTuner
//
//  Created by wxm on 5/17/25.
//

import SwiftUI

struct NeumorphicButton: View {
    var text: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Color(white: 0.1))
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    ZStack {
                        // 背景颜色（浅灰）
                        Color(red: 0.9, green: 0.9, blue: 0.9)
                        
                        // 外阴影（模拟 Neumorphic 效果）
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(white: 0.9))
                            .shadow(
                                color: Color.white.opacity(0.9),
                                radius: 6, x: -6, y: -6
                            )
                            .shadow(
                                color: Color.gray.opacity(0.4),
                                radius: 6, x: 6, y: 6
                            )
                    }
                )
                .cornerRadius(8)
        }
        .buttonStyle(NeumorphicButtonStyle())
    }
}

// 自定义 ButtonStyle 处理按压效果
struct NeumorphicButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .shadow(
                color: configuration.isPressed ? Color.clear : Color.white.opacity(0.9),
                radius: 6, x: -6, y: -6
            )
            .shadow(
                color: configuration.isPressed ? Color.clear : Color.gray.opacity(0.4),
                radius: 6, x: 6, y: 6
            )
            .overlay(
                Group {
                    if configuration.isPressed {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.1))
                            .shadow(
                                color: Color.black.opacity(0.2),
                                radius: 2, x: 2, y: 2
                            )
                            .shadow(
                                color: Color.white.opacity(0.7),
                                radius: 2, x: -2, y: -2
                            )
                    }
                }
            )
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}



#Preview {
    NeumorphicButton(text: "a"){
        print("aaaa")
    }
}
