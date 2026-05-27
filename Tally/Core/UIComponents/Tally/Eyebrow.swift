import SwiftUI

struct Eyebrow: View {
    let text: String
    let color: Color

    init(_ text: String, color: Color = .tallyInkFaint) {
        self.text = text
        self.color = color
    }

    var body: some View {
        Text(text)
            .font(TallyType.display(11, weight: .semibold))
            .tracking(11 * 0.04)
            .textCase(.uppercase)
            .foregroundStyle(color)
            .lineLimit(1)
    }
}

#Preview("Eyebrow Light") {
    VStack(alignment: .leading, spacing: TallySpacing.s3) {
        Eyebrow("today")
        Eyebrow("categories", color: .tallyAccent)
    }
    .padding()
    .background(Color.tallyBg)
    .preferredColorScheme(.light)
}

#Preview("Eyebrow Dark") {
    VStack(alignment: .leading, spacing: TallySpacing.s3) {
        Eyebrow("today")
        Eyebrow("categories", color: .tallyAccent)
    }
    .padding()
    .background(Color.tallyBg)
    .preferredColorScheme(.dark)
}
