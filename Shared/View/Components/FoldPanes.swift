import SwiftUI

struct FoldPanes {
    let axis: Axis
    let before: CGSize
    let after: CGSize
    let spacing: CGFloat

    init?(_ geometry: GeometryProxy) {
        guard #available(iOS 27.1, macOS 27.1, *),
              let division = geometry.reservedRegions(kind: .division).first else { return nil }

        // The frame is local to this view and already includes the recommended margins.
        let fold = division.frame
        let size = geometry.size
        if fold.height >= fold.width {
            guard fold.minX > 0, fold.maxX < size.width,
                  fold.maxY > 0, fold.minY < size.height else { return nil }
            axis = .horizontal
            before = CGSize(width: fold.minX, height: size.height)
            after = CGSize(width: size.width - fold.maxX, height: size.height)
            spacing = fold.width
        } else {
            guard fold.minY > 0, fold.maxY < size.height,
                  fold.maxX > 0, fold.minX < size.width else { return nil }
            axis = .vertical
            before = CGSize(width: size.width, height: fold.minY)
            after = CGSize(width: size.width, height: size.height - fold.maxY)
            spacing = fold.height
        }
    }
}
