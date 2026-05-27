import SwiftUI

struct BillsListHeader: View {
    let timeTitle: String
    let onBack: () -> Void
    let onTimeTap: () -> Void
    @Binding var selection: BillType

    var body: some View {
        HStack {
            LegacyBackButton {
                onBack()
            }

            Spacer()

            Button {
                onTimeTap()
            } label: {
                HStack(spacing: LegacySpacing.xs) {
                    Text(timeTitle)
                        .font(LegacyTypography.body)
                        .foregroundStyle(LegacyColors.textPrimary)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(LegacyColors.textSecondary)
                }
                .padding(.horizontal, LegacySpacing.md)
                .padding(.vertical, LegacySpacing.xs)
                .background(LegacyColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)

            Spacer()

            LegacyBillTypeSegmentedControl(selection: $selection)
        }
    }
}
