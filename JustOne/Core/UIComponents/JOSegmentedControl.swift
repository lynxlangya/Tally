import SwiftUI

struct JOSegmentedControl: View {
    let items: [String]
    @Binding var selectedIndex: Int

    init(items: [String], selectedIndex: Binding<Int>) {
        self.items = items
        self._selectedIndex = selectedIndex
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items.indices, id: \.self) { index in
                Button(action: { selectedIndex = index }) {
                    Text(items[index])
                        .font(JOTypography.caption)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, JOSpacing.sm)
                }
                .foregroundStyle(selectedIndex == index ? JOColors.accentForeground : JOColors.textSecondary)
                .background(selectedIndex == index ? JOColors.accent : Color.clear)
            }
        }
        .background(JOColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: JORadius.pill, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: JORadius.pill, style: .continuous)
                .stroke(JOColors.divider, lineWidth: 1)
        )
    }
}
