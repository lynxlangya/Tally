import SwiftUI

struct JOAmountText: View {
    enum Size {
        case large
        case medium
        case small
        case row
    }

    let cents: Int
    let sign: String?
    let size: Size
    let color: Color

    init(cents: Int, sign: String? = nil, size: Size = .medium, color: Color = JOColors.textPrimary) {
        self.cents = cents
        self.sign = sign
        self.size = size
        self.color = color
    }

    var body: some View {
        Text(displayText)
            .font(font)
            .foregroundStyle(color)
    }

    private var displayText: String {
        let amount = MoneyFormatter.string(fromCents: cents)
        return (sign ?? "") + amount
    }

    private var font: Font {
        switch size {
        case .large:
            return JOTypography.titleLarge
        case .medium:
            return JOTypography.title
        case .small:
            return JOTypography.body
        case .row:
            return .system(size: 18, weight: .semibold)
        }
    }
}
