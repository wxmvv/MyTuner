import SwiftUI

extension View {
    @ViewBuilder
    func watchGlass<S: Shape>(in shape: S, interactive: Bool = false) -> some View {
        if #available(watchOS 26.0, *) {
            glassEffect(interactive ? .regular.interactive() : .regular, in: shape)
        } else {
            background(.regularMaterial, in: shape)
        }
    }
}
