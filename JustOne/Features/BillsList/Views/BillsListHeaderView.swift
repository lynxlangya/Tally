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

            BillTypeToggle(selection: $selection)
        }
    }
}

private struct BillTypeToggle: View {
    @Binding var selection: BillType

    var body: some View {
        HStack(spacing: 0) {
            toggleButton(title: "支", type: .expense)
            toggleButton(title: "收", type: .income)
        }
        .padding(4)
        .background(JOColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(JOColors.cardBorder, lineWidth: 1)
        )
    }

    @ViewBuilder
    private func toggleButton(title: String, type: BillType) -> some View {
        let isSelected = selection == type
        Button {
            selection = type
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(isSelected ? JOColors.accentForeground : JOColors.textSecondary)
                .frame(width: 36, height: 28)
                .background(isSelected ? JOColors.accent : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
