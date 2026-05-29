import SwiftUI

struct Yen: View {
    let fontSize: CGFloat
    let color: Color

    init(fontSize: CGFloat, color: Color = .tallyInk) {
        self.fontSize = fontSize
        self.color = color
    }

    var body: some View {
        Text(MoneyFormatter.currencySymbol())
            .font(TallyType.num(fontSize * 0.62, weight: .light))
            .foregroundStyle(color.opacity(0.55))
            .baselineOffset(-fontSize * 0.06)
            .padding(.trailing, fontSize * 0.06)
    }
}

#Preview("Yen Light") {
    HStack(alignment: .firstTextBaseline, spacing: TallySpacing.s4) {
        Yen(fontSize: 28)
        Yen(fontSize: 56, color: .tallyAccent)
    }
    .padding()
    .background(Color.tallyBg)
    .preferredColorScheme(.light)
}

#Preview("Yen Dark") {
    HStack(alignment: .firstTextBaseline, spacing: TallySpacing.s4) {
        Yen(fontSize: 28)
        Yen(fontSize: 56, color: .tallyAccent)
    }
    .padding()
    .background(Color.tallyBg)
    .preferredColorScheme(.dark)
}
