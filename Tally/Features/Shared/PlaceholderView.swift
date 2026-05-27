import SwiftUI

struct PlaceholderView: View {
    let title: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tabBarVisibility) private var tabBarVisibility

    var body: some View {
        VStack(spacing: LegacySpacing.lg) {
            header

            VStack(spacing: LegacySpacing.sm) {
                Text(title)
                    .font(LegacyTypography.title)
                    .foregroundStyle(LegacyColors.textPrimary)
                Text("占位页")
                    .font(LegacyTypography.body)
                    .foregroundStyle(LegacyColors.textSecondary)
            }

            Spacer()
        }
        .padding(.horizontal, LegacySpacing.lg)
        .padding(.top, LegacySpacing.lg)
        .background(LegacyColors.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            tabBarVisibility?.setVisible(false)
        }
    }

    private var header: some View {
        LegacyHeaderBar(
            showsTrailingPlaceholder: false
        ) {
            dismiss()
        }
    }
}
