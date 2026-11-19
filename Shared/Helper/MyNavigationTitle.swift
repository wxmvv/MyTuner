//
//  MyNavigationTitle.swift
//  MyTuner
//
//  Created by wxm on 4/11/25.
//

import SwiftUI

struct MyNavigationTitle: ViewModifier {
    var text: LocalizedStringKey
    var show: Bool
    func body(content: Content) -> some View {
        if !show {
            content
        } else {
            content
                .navigationTitle(Text(text))
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

extension View {
    func myNavBarTitle(_ text: LocalizedStringKey,show: Bool) -> some View {
        modifier(MyNavigationTitle(text: text, show: show))
    }
}
