import Foundation
import SwiftUI

struct TallyAmountText: View {
    enum Sign {
        case none
        case expense
        case income

        var symbol: String {
            switch self {
            case .none:
                return ""
            case .expense:
                return "−"
            case .income:
                return "+"
            }
        }
    }

    let cents: Int
    let sign: Sign
    let size: CGFloat
    let weight: Font.Weight
    let color: Color
    let dim: Bool
    let showYen: Bool

    init(
        cents: Int,
        sign: Sign = .none,
        size: CGFloat,
        weight: Font.Weight = .medium,
        color: Color = .tallyInk,
        dim: Bool = false,
        showYen: Bool = true
    ) {
        self.cents = cents
        self.sign = sign
        self.size = size
        self.weight = weight
        self.color = color
        self.dim = dim
        self.showYen = showYen
    }

    var body: some View {
        formattedText(
            cents: cents,
            sign: sign,
            size: size,
            weight: weight,
            color: dim ? .tallyInkDim : color,
            dim: dim,
            showYen: showYen
        )
    }

    static func formattedText(
        cents: Int,
        sign: Sign = .none,
        size: CGFloat,
        weight: Font.Weight = .medium,
        color: Color = .tallyInk,
        dim: Bool = false,
        showYen: Bool = true
    ) -> Text {
        let parts = amountParts(cents: cents)
        let resolvedColor = dim ? Color.tallyInkDim : color
        let decimalSize = size * 0.62
        var text = Text("")

        if !sign.symbol.isEmpty {
            text = text + Text(sign.symbol)
                .font(TallyType.num(size, weight: weight))
                .foregroundColor(resolvedColor)
        }

        if showYen {
            text = text + Text("¥")
                .font(TallyType.num(decimalSize, weight: .light))
                .foregroundColor(resolvedColor.opacity(0.55))
                .baselineOffset(-size * 0.06)
        }

        return text
            + Text(parts.integer)
                .font(TallyType.num(size, weight: weight))
                .foregroundColor(resolvedColor)
            + Text(".\(parts.decimal)")
                .font(TallyType.num(decimalSize, weight: weight))
                .foregroundColor(resolvedColor.opacity(0.5))
    }

    static func amountParts(cents: Int) -> (integer: String, decimal: String) {
        let absCents = abs(cents)
        let yuan = absCents / 100
        let cent = absCents % 100
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "en_US")
        formatter.usesGroupingSeparator = true
        let integer = formatter.string(from: NSNumber(value: yuan)) ?? "\(yuan)"
        return (integer, String(format: "%02d", cent))
    }
}

#Preview("TallyAmountText Light") {
    TallyAmountTextPreview()
        .preferredColorScheme(.light)
}

#Preview("TallyAmountText Dark") {
    TallyAmountTextPreview()
        .preferredColorScheme(.dark)
}

private struct TallyAmountTextPreview: View {
    private let sizes: [CGFloat] = [14, 17, 22, 28, 56, 84]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TallySpacing.s4) {
                ForEach(sizes, id: \.self) { size in
                    VStack(alignment: .leading, spacing: TallySpacing.s2) {
                        Eyebrow("SIZE \(Int(size))")
                        TallyAmountText(cents: 12345678, sign: .expense, size: size)
                        TallyAmountText(cents: -987654, sign: .income, size: size, color: .tallyAccent)
                        TallyAmountText(cents: 4200, size: size, dim: true)
                    }
                }
            }
            .padding()
        }
        .background(Color.tallyBg)
    }
}
