import SwiftUI

struct JOBillTypeSegmentedControl: View {
    @Binding var selection: BillType
    let expenseTitle: String
    let incomeTitle: String

    init(
        selection: Binding<BillType>,
        expenseTitle: String = "支",
        incomeTitle: String = "收"
    ) {
        self._selection = selection
        self.expenseTitle = expenseTitle
        self.incomeTitle = incomeTitle
    }

    var body: some View {
        HStack(spacing: 0) {
            toggleButton(title: expenseTitle, type: .expense)
            toggleButton(title: incomeTitle, type: .income)
        }
        .padding(4)
        .background(JOColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(JOColors.cardBorder, lineWidth: 1)
        )
    }

    private func toggleButton(title: String, type: BillType) -> some View {
        let isSelected = selection == type
        return Button {
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
