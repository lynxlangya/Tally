import SwiftUI

struct TallyComponentsGallery: View {
    @State private var segment = "expense"
    @State private var sheetPresented = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TallySpacing.s7) {
                section("Marks") {
                    HStack(spacing: TallySpacing.s5) {
                        TallyMark(size: 28, variant: .one)
                        TallyMark(size: 36, variant: .five, color: .tallyAccent)
                    }
                }

                section("Amount") {
                    VStack(alignment: .leading, spacing: TallySpacing.s3) {
                        TallyAmountText(cents: 12345678, sign: .expense, size: 28)
                        TallyAmountText(cents: 9900, sign: .income, size: 22, color: .tallyAccent)
                        TallyAmountText(cents: 4200, size: 17, dim: true)
                    }
                }

                section("Labels") {
                    HStack(spacing: TallySpacing.s3) {
                        Eyebrow("today")
                        Chip("刻痕")
                        Chip("收入", tone: .accent)
                        Chip("筛选", tone: .outline, size: .xs)
                    }
                }

                section("Controls") {
                    Segmented(
                        value: $segment,
                        options: [("expense", "支出"), ("income", "收入")]
                    )
                }

                section("Tiles") {
                    HStack(spacing: TallySpacing.s4) {
                        CategoryTile(iconName: "fork-knife", color: .catTerracotta)
                        CategoryTile(iconName: "shopping-cart", color: .catTeal)
                        CategoryTile(iconName: "money-wavy", color: .catOchre, filled: .solid)
                    }
                }

                section("Sparkline") {
                    Sparkline(
                        data: [2, 5, 4, 9, 7, 12, 8],
                        baseline: true,
                        width: 280,
                        height: 64
                    )
                }

                section("Sheet") {
                    Button("打开") {
                        sheetPresented = true
                    }
                    .font(TallyType.body(15, weight: .semibold))
                    .foregroundStyle(Color.tallyAccentInk)
                    .padding(.horizontal, TallySpacing.s5)
                    .padding(.vertical, TallySpacing.s3)
                    .background(Color.tallyAccent)
                    .clipShape(Capsule(style: .continuous))
                }
            }
            .padding(TallySpacing.s6)
        }
        .background(Color.tallyBg)
        .tallySheet(isPresented: $sheetPresented, heightFraction: 0.42) {
            VStack(spacing: TallySpacing.s4) {
                Eyebrow("preview")
                Text("Tally Sheet")
                    .font(TallyType.display(24, weight: .semibold))
                    .foregroundStyle(Color.tallyInk)
                Button("关闭") {
                    sheetPresented = false
                }
                .font(TallyType.body(15, weight: .medium))
                .foregroundStyle(Color.tallyAccent)
            }
            .padding(TallySpacing.s6)
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: TallySpacing.s4) {
            Eyebrow(title)
            content()
        }
    }
}

#Preview("Tally Components Light") {
    TallyComponentsGallery()
        .preferredColorScheme(.light)
}

#Preview("Tally Components Dark") {
    TallyComponentsGallery()
        .preferredColorScheme(.dark)
}
