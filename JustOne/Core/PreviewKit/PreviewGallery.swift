import SwiftUI

struct PreviewGallery: View {
    @State private var selectedSegment = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: JOSpacing.xl) {
                Text("Preview Gallery")
                    .font(JOTypography.title)
                    .foregroundStyle(JOColors.textPrimary)

                VStack(alignment: .leading, spacing: JOSpacing.md) {
                    Text("Buttons")
                        .font(JOTypography.caption)
                        .foregroundStyle(JOColors.textSecondary)
                    JOPrimaryButton("Primary") {}
                    JOPrimaryButton("Disabled", isEnabled: false) {}
                    HStack(spacing: JOSpacing.md) {
                        JOIconButton(systemName: "calendar") {}
                        JOIconButton(systemName: "chevron.right") {}
                    }
                }

                VStack(alignment: .leading, spacing: JOSpacing.md) {
                    Text("Segmented")
                        .font(JOTypography.caption)
                        .foregroundStyle(JOColors.textSecondary)
                    JOSegmentedControl(items: ["Expense", "Income"], selectedIndex: $selectedSegment)
                }

                VStack(alignment: .leading, spacing: JOSpacing.md) {
                    Text("Amounts")
                        .font(JOTypography.caption)
                        .foregroundStyle(JOColors.textSecondary)
                    JOAmountText(cents: 428560, size: .large)
                    JOAmountText(cents: 850000, sign: "+", size: .medium, color: JOColors.accent)
                    JOAmountText(cents: 825, sign: "-", size: .small)
                }

                VStack(alignment: .leading, spacing: JOSpacing.md) {
                    Text("Cards & Rows")
                        .font(JOTypography.caption)
                        .foregroundStyle(JOColors.textSecondary)
                    JOCard {
                        VStack(alignment: .leading, spacing: JOSpacing.sm) {
                            Text("This Month")
                                .font(JOTypography.caption)
                                .foregroundStyle(JOColors.textSecondary)
                            JOAmountText(cents: 428560, size: .medium)
                        }
                    }
                    JOListRow(
                        iconName: "cup.and.saucer.fill",
                        iconBackground: JOColors.accent.opacity(0.2),
                        title: "Coffee",
                        subtitle: "09:41",
                        amountCents: 550,
                        amountSign: "-"
                    )
                }

                VStack(alignment: .leading, spacing: JOSpacing.md) {
                    Text("Chips & FAB")
                        .font(JOTypography.caption)
                        .foregroundStyle(JOColors.textSecondary)
                    HStack(spacing: JOSpacing.md) {
                        JOChip("Today")
                        JOChip("Selected", isEmphasized: true)
                    }
                    JOFAB {}
                }
            }
            .padding(JOSpacing.xl)
        }
        .background(JOColors.background.ignoresSafeArea())
    }
}

#Preview("Light") {
    PreviewGallery()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    PreviewGallery()
        .preferredColorScheme(.dark)
}
