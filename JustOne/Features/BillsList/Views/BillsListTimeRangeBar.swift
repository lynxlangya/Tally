import SwiftUI

struct TimeRangeBar: View {
    @Binding var selection: BillsListViewModel.TimeRange

    var body: some View {
        HStack(spacing: 0) {
            ForEach(BillsListViewModel.TimeRange.allCases) { range in
                Button {
                    selection = range
                } label: {
                    Text(range.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(selection == range ? JOColors.accentForeground : JOColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(selection == range ? JOColors.accent : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(JOColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(JOColors.cardBorder, lineWidth: 1)
        )
        .shadow(color: JOShadows.floating.color, radius: JOShadows.floating.radius, x: 0, y: JOShadows.floating.y)
    }
}
