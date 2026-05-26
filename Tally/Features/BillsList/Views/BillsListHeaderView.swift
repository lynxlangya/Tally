import SwiftUI

struct BillsListHeader: View {
    let timeTitle: String
    let onBack: () -> Void
    let onTimeTap: () -> Void
    @Binding var selection: BillType

    var body: some View {
        HStack {
            JOBackButton {
                onBack()
            }

            Spacer()

            Button {
                onTimeTap()
            } label: {
                HStack(spacing: JOSpacing.xs) {
                    Text(timeTitle)
                        .font(JOTypography.body)
                        .foregroundStyle(JOColors.textPrimary)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(JOColors.textSecondary)
                }
                .padding(.horizontal, JOSpacing.md)
                .padding(.vertical, JOSpacing.xs)
                .background(JOColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)

            Spacer()

            JOBillTypeSegmentedControl(selection: $selection)
        }
    }
}
