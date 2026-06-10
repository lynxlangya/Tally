import Foundation
import SwiftUI

struct TallyAmountText: View {
    enum AnimationStyle {
        case none
        case numeric
    }

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
    let showSymbol: Bool
    let locale: Locale
    let animationStyle: AnimationStyle

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        cents: Int,
        sign: Sign = .none,
        size: CGFloat,
        weight: Font.Weight = .medium,
        color: Color = .tallyInk,
        dim: Bool = false,
        showSymbol: Bool = true,
        locale: Locale = LanguageManager.shared.currentLocale,
        animationStyle: AnimationStyle = .none
    ) {
        self.cents = cents
        self.sign = sign
        self.size = size
        self.weight = weight
        self.color = color
        self.dim = dim
        self.showSymbol = showSymbol
        self.locale = locale
        self.animationStyle = animationStyle
    }

    var body: some View {
        let text = Self.formattedText(
            cents: cents,
            sign: sign,
            size: size,
            weight: weight,
            color: dim ? .tallyInkDim : color,
            dim: dim,
            showSymbol: showSymbol,
            locale: locale
        )

        if shouldAnimate {
            text
                .contentTransition(.numericText(value: Double(cents) / 100))
                .animation(.tallyEmph, value: animationValue)
        } else {
            text
        }
    }

    static func formattedText(
        cents: Int,
        sign: Sign = .none,
        size: CGFloat,
        weight: Font.Weight = .medium,
        color: Color = .tallyInk,
        dim: Bool = false,
        showSymbol: Bool = true,
        locale: Locale = LanguageManager.shared.currentLocale
    ) -> Text {
        let parts = amountParts(cents: cents, locale: locale)
        let resolvedColor = dim ? Color.tallyInkDim : color
        let decimalSize = size * 0.62
        let signText = Text(sign.symbol)
            .font(TallyType.num(size, weight: weight))
            .foregroundColor(resolvedColor)
        let symbolText = Text(MoneyFormatter.currencySymbol())
            .font(TallyType.num(decimalSize, weight: .light))
            .foregroundColor(resolvedColor.opacity(0.55))
            .baselineOffset(-size * 0.06)
        let integerText = Text(parts.integer)
            .font(TallyType.num(size, weight: weight))
            .foregroundColor(resolvedColor)
        let decimalText = Text(".\(parts.decimal)")
            .font(TallyType.num(decimalSize, weight: weight))
            .foregroundColor(resolvedColor.opacity(0.5))

        switch (sign.symbol.isEmpty, showSymbol) {
        case (false, true):
            return Text("\(signText)\(symbolText)\(integerText)\(decimalText)")
        case (false, false):
            return Text("\(signText)\(integerText)\(decimalText)")
        case (true, true):
            return Text("\(symbolText)\(integerText)\(decimalText)")
        case (true, false):
            return Text("\(integerText)\(decimalText)")
        }
    }

    static func amountParts(cents: Int, locale: Locale = LanguageManager.shared.currentLocale) -> MoneyFormatter.Parts {
        MoneyFormatter.parts(fromCents: cents, locale: locale)
    }

    private var shouldAnimate: Bool {
        guard !reduceMotion else {
            return false
        }

        switch animationStyle {
        case .none:
            return false
        case .numeric:
            return true
        }
    }

    private var animationValue: String {
        "\(sign.symbol)|\(showSymbol)|\(MoneyFormatter.currencySymbol())|\(cents)"
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
                        TallyAmountText(cents: 987654, sign: .income, size: size, color: .tallyAccent)
                        TallyAmountText(cents: 4200, size: size, dim: true)
                    }
                }
            }
            .padding()
        }
        .background(Color.tallyBg)
    }
}
