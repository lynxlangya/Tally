import SwiftUI
import UIKit

enum TallyType {
    static let sizeScale: [CGFloat] = [10, 11, 12, 13, 14, 15, 17, 22, 24, 28, 32, 56, 64, 84]

    static func display(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        scaledSystem(size, weight: weight, relativeTo: textStyle(for: size))
    }

    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        scaledSystem(size, weight: weight, relativeTo: textStyle(for: size))
    }

    static func num(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        display(size, weight: weight)
            .monospacedDigit()
    }

    static func scaledPointSizeForTesting(
        _ size: CGFloat,
        contentSizeCategory: UIContentSizeCategory
    ) -> CGFloat {
        let traitCollection = UITraitCollection(preferredContentSizeCategory: contentSizeCategory)
        return scaledPointSize(size, relativeTo: textStyle(for: size), compatibleWith: traitCollection)
    }

    private static func scaledSystem(
        _ size: CGFloat,
        weight: Font.Weight,
        relativeTo textStyle: UIFont.TextStyle
    ) -> Font {
        .system(
            size: scaledPointSize(size, relativeTo: textStyle, compatibleWith: nil),
            weight: weight,
            design: .default
        )
    }

    private static func scaledPointSize(
        _ size: CGFloat,
        relativeTo textStyle: UIFont.TextStyle,
        compatibleWith traitCollection: UITraitCollection?
    ) -> CGFloat {
        UIFontMetrics(forTextStyle: textStyle).scaledValue(for: size, compatibleWith: traitCollection)
    }

    private static func textStyle(for size: CGFloat) -> UIFont.TextStyle {
        let normalized = sizeScale.min { lhs, rhs in
            abs(lhs - size) < abs(rhs - size)
        } ?? size

        switch normalized {
        case ...11:
            return .caption2
        case ...13:
            return .caption1
        case ...15:
            return .subheadline
        case ...17:
            return .body
        case ...22:
            return .title3
        case ...24:
            return .title2
        default:
            return .largeTitle
        }
    }
}
