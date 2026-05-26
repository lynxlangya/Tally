import SwiftUI

struct PlaceholderView: View {
    let title: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tabBarVisibility) private var tabBarVisibility

    var body: some View {
        VStack(spacing: JOSpacing.lg) {
            header

            VStack(spacing: JOSpacing.sm) {
                Text(title)
                    .font(JOTypography.title)
                    .foregroundStyle(JOColors.textPrimary)
                Text("占位页")
                    .font(JOTypography.body)
                    .foregroundStyle(JOColors.textSecondary)
            }

            Spacer()
        }
        .padding(.horizontal, JOSpacing.lg)
        .padding(.top, JOSpacing.lg)
        .background(JOColors.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            tabBarVisibility?.setVisible(false)
        }
    }

    private var header: some View {
        JOHeaderBar(
            showsTrailingPlaceholder: false
        ) {
            dismiss()
        }
    }
}
