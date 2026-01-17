import SwiftUI

struct ProfileView: View {
    @Environment(\.appEnvironment) private var environment
    @State private var showsDebug = false

    var body: some View {
        ZStack {
            JOColors.background.ignoresSafeArea()

            VStack(spacing: JOSpacing.lg) {
                header

                ScrollView {
                    VStack(spacing: JOSpacing.lg) {
                        JOCard {
                            VStack(alignment: .leading, spacing: JOSpacing.sm) {
                                Text("个人中心")
                                    .font(JOTypography.headline)
                                    .foregroundStyle(JOColors.textPrimary)
                                Text("入口占位")
                                    .font(JOTypography.body)
                                    .foregroundStyle(JOColors.textSecondary)
                            }
                        }

                        #if DEBUG
                        JOPrimaryButton("Debug") {
                            showsDebug = true
                        }
                        #endif
                    }
                    .padding(.bottom, 120)
                }
            }
            .padding(.horizontal, JOSpacing.lg)
            .padding(.top, JOSpacing.xl)
        }
        .toolbar(.hidden, for: .navigationBar)
        #if DEBUG
        .navigationDestination(isPresented: $showsDebug) {
            DebugView(
                repository: environment.container.repositories.bill,
                seedService: environment.container.services.seed
            )
        }
        #endif
    }

    private var header: some View {
        HStack {
            Text("我的")
                .font(JOTypography.title)
                .foregroundStyle(JOColors.textPrimary)
            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
    .environment(\.appEnvironment, .preview)
}
