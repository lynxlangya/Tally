import SwiftUI

struct HomeView: View {
    @Environment(\.appEnvironment) private var environment
    @State private var showsBillsList = false

    var body: some View {
        ZStack {
            JOColors.background.ignoresSafeArea()

            VStack(spacing: JOSpacing.lg) {
                header

                ScrollView {
                    VStack(alignment: .leading, spacing: JOSpacing.lg) {
                        JOCard {
                            VStack(alignment: .leading, spacing: JOSpacing.sm) {
                                Text("本月概览")
                                    .font(JOTypography.caption)
                                    .foregroundStyle(JOColors.textSecondary)
                                JOAmountText(cents: 0, size: .medium)
                            }
                        }

                        JOCard {
                            Text("账单列表占位")
                                .font(JOTypography.body)
                                .foregroundStyle(JOColors.textSecondary)
                        }
                    }
                    .padding(.bottom, 120)
                }
            }
            .padding(.horizontal, JOSpacing.lg)
            .padding(.top, JOSpacing.xl)
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $showsBillsList) {
            BillsListView(repository: environment.container.repositories.bill)
        }
    }

    private var header: some View {
        HStack {
            Text("首页")
                .font(JOTypography.title)
                .foregroundStyle(JOColors.textPrimary)
            Spacer()
            JOIconButton(systemName: "list.bullet") {
                showsBillsList = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .environment(\.appEnvironment, .preview)
}
