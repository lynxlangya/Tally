import SwiftUI

enum TallyType {
    static let sizeScale: [CGFloat] = [10, 11, 12, 13, 14, 15, 17, 22, 24, 28, 32, 56, 64, 84]

    static func display(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    static func num(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        display(size, weight: weight)
            .monospacedDigit()
    }
}
