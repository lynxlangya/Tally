import SwiftUI

struct TallyTokensPreview: View {
    private let accentTokens: [(String, Color)] = [
        ("Accent", .tallyAccent),
        ("Accent Hi", .tallyAccentHi),
        ("Accent Lo", .tallyAccentLo),
        ("Accent Ink", .tallyAccentInk),
        ("Accent Tint", .tallyAccentTint)
    ]

    private let surfaceTokens: [(String, Color)] = [
        ("Bg", .tallyBg),
        ("Surface", .tallySurface),
        ("Surface 2", .tallySurface2),
        ("Surface 3", .tallySurface3),
        ("Line", .tallyLine),
        ("Line Hi", .tallyLineHi),
        ("Scrim", .tallyScrim)
    ]

    private let inkTokens: [(String, Color)] = [
        ("Ink", .tallyInk),
        ("Ink Dim", .tallyInkDim),
        ("Ink Faint", .tallyInkFaint),
        ("Ink Ghost", .tallyInkGhost)
    ]

    private let categoryTokens: [(String, Color)] = [
        ("Terracotta", .catTerracotta),
        ("Persimmon", .catPersimmon),
        ("Ochre", .catOchre),
        ("Olive", .catOlive),
        ("Moss", .catMoss),
        ("Sage", .catSage),
        ("Teal", .catTeal),
        ("Slate", .catSlate),
        ("Indigo", .catIndigo),
        ("Plum", .catPlum),
        ("Rose", .catRose),
        ("Ash", .catAsh)
    ]

    private let columns = [
        GridItem(.adaptive(minimum: 92), spacing: TallySpacing.s3)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TallySpacing.s7) {
                tokenSection("Accent", tokens: accentTokens)
                tokenSection("Surface", tokens: surfaceTokens)
                tokenSection("Ink", tokens: inkTokens)
                tokenSection("Categories", tokens: categoryTokens)
            }
            .padding(TallySpacing.s6)
        }
        .background(Color.tallyBg)
    }

    private func tokenSection(_ title: String, tokens: [(String, Color)]) -> some View {
        VStack(alignment: .leading, spacing: TallySpacing.s4) {
            Text(title)
                .font(TallyType.display(22, weight: .semibold))
                .foregroundStyle(Color.tallyInk)

            LazyVGrid(columns: columns, alignment: .leading, spacing: TallySpacing.s3) {
                ForEach(tokens, id: \.0) { token in
                    VStack(alignment: .leading, spacing: TallySpacing.s2) {
                        RoundedRectangle(cornerRadius: TallyRadii.md, style: .continuous)
                            .fill(token.1)
                            .frame(height: 64)
                            .overlay(
                                RoundedRectangle(cornerRadius: TallyRadii.md, style: .continuous)
                                    .stroke(Color.tallyLineHi, lineWidth: 1)
                            )

                        Text(token.0)
                            .font(TallyType.body(12, weight: .medium))
                            .foregroundStyle(Color.tallyInkDim)
                            .lineLimit(1)
                    }
                }
            }
        }
    }
}

#Preview("Tally Tokens Light") {
    TallyTokensPreview()
        .preferredColorScheme(.light)
}

#Preview("Tally Tokens Dark") {
    TallyTokensPreview()
        .preferredColorScheme(.dark)
}
