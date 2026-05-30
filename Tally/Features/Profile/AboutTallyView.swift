import SwiftUI
import MessageUI
import UIKit

struct AboutTallyView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tabBarVisibility) private var tabBarVisibility

    private let onBack: (() -> Void)?
    private let supportEmail = "hey@wangyun.fan"

    @State private var showsFeedbackComposer = false
    @State private var showsMailUnavailableAlert = false

    init(onBack: (() -> Void)? = nil) {
        self.onBack = onBack
    }

    var body: some View {
        ZStack {
            Color.tallyBg.ignoresSafeArea()

            VStack(spacing: 0) {
                TallyNavHeader(title: TallyLocalization.text("about_tally", locale: LanguageManager.shared.currentLocale), onBack: close)

                ScrollView {
                    VStack(alignment: .leading, spacing: TallySpacing.s6) {
                        heroCard
                        privacySection
                        dataSection
                        supportSection
                        acknowledgementsSection
                    }
                    .padding(.horizontal, TallySpacing.s4)
                    .padding(.top, TallySpacing.s2)
                    .padding(.bottom, TallySpacing.s9)
                }
                .scrollIndicators(.hidden)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            tabBarVisibility?.setVisible(false)
        }
        .sheet(isPresented: $showsFeedbackComposer) {
            FeedbackMailComposer(
                recipient: supportEmail,
                subject: supportMailSubject,
                body: supportMailBody
            ) {
                showsFeedbackComposer = false
            }
        }
        .alert(
            TallyLocalization.text("feedback_email_unavailable_title", locale: LanguageManager.shared.currentLocale),
            isPresented: $showsMailUnavailableAlert
        ) {
            Button(TallyLocalization.text("copy_email", locale: LanguageManager.shared.currentLocale)) {
                UIPasteboard.general.string = supportEmail
            }
            Button(TallyLocalization.text(.gotIt, locale: LanguageManager.shared.currentLocale), role: .cancel) { }
        } message: {
            Text(TallyLocalization.text("feedback_email_unavailable_detail", locale: LanguageManager.shared.currentLocale))
        }
    }

    private func close() {
        if let onBack {
            onBack()
        } else {
            dismiss()
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: TallySpacing.s5) {
            HStack(alignment: .center, spacing: TallySpacing.s4) {
                RoundedRectangle(cornerRadius: TallyRadii.lg, style: .continuous)
                    .fill(Color.tallySurface2)
                    .frame(width: 64, height: 64)
                    .overlay(
                        TallyMark(size: 30, variant: .five, color: .tallyAccent, strokeWidth: 2.2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: TallyRadii.lg, style: .continuous)
                            .stroke(Color.tallyLine, lineWidth: 0.5)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Tally")
                        .font(TallyType.display(28, weight: .semibold))
                        .foregroundStyle(Color.tallyInk)

                    Text(TallyLocalization.text("local_single_currency", locale: LanguageManager.shared.currentLocale))
                        .font(TallyType.body(13, weight: .medium))
                        .foregroundStyle(Color.tallyInkDim)
                }

                Spacer(minLength: 0)
            }

            AboutKeyValueRow(title: TallyLocalization.text("version", locale: LanguageManager.shared.currentLocale), value: versionText)
            AboutKeyValueRow(
                title: TallyLocalization.text("data_scope", locale: LanguageManager.shared.currentLocale),
                value: TallyLocalization.text("data_scope_value", locale: LanguageManager.shared.currentLocale)
            )
        }
        .padding(TallySpacing.s5)
        .background(Color.tallySurface)
        .clipShape(RoundedRectangle(cornerRadius: TallyRadii.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: TallyRadii.xl, style: .continuous)
                .stroke(Color.tallyLine, lineWidth: 0.5)
        )
        .tallyShadow(.shadow2)
    }

    private var privacySection: some View {
        AboutSection(
            title: TallyLocalization.text("privacy_policy", locale: LanguageManager.shared.currentLocale),
            rows: [
                AboutInfoRow(
                    icon: "lock.fill",
                    title: TallyLocalization.text("local_by_default", locale: LanguageManager.shared.currentLocale),
                    detail: TallyLocalization.text("local_by_default_detail", locale: LanguageManager.shared.currentLocale)
                ),
                AboutInfoRow(
                    icon: "network.slash",
                    title: TallyLocalization.text("no_network_analytics", locale: LanguageManager.shared.currentLocale),
                    detail: TallyLocalization.text("no_network_analytics_detail", locale: LanguageManager.shared.currentLocale)
                ),
                AboutInfoRow(
                    icon: "bell.fill",
                    title: TallyLocalization.text("notification_opt_in", locale: LanguageManager.shared.currentLocale),
                    detail: TallyLocalization.text("notification_opt_in_detail", locale: LanguageManager.shared.currentLocale)
                )
            ]
        )
    }

    private var dataSection: some View {
        AboutSection(
            title: TallyLocalization.text("data_backup", locale: LanguageManager.shared.currentLocale),
            rows: [
                AboutInfoRow(
                    icon: "externaldrive.fill",
                    title: TallyLocalization.text("manual_import_export", locale: LanguageManager.shared.currentLocale),
                    detail: TallyLocalization.text("manual_import_export_detail", locale: LanguageManager.shared.currentLocale)
                ),
                AboutInfoRow(
                    icon: "photo.fill",
                    title: TallyLocalization.text("avatar_selection", locale: LanguageManager.shared.currentLocale),
                    detail: TallyLocalization.text("avatar_selection_detail", locale: LanguageManager.shared.currentLocale)
                )
            ]
        )
    }

    private var supportSection: some View {
        VStack(alignment: .leading, spacing: TallySpacing.s4) {
            AboutSectionTitle(TallyLocalization.text("support", locale: LanguageManager.shared.currentLocale))

            Button(action: openSupportFeedback) {
                HStack(spacing: TallySpacing.s4) {
                    AboutIcon("envelope.fill")

                    VStack(alignment: .leading, spacing: 3) {
                        Text(TallyLocalization.text("report_issue", locale: LanguageManager.shared.currentLocale))
                            .font(TallyType.body(14, weight: .semibold))
                            .foregroundStyle(Color.tallyInk)
                        Text(TallyLocalization.text("report_issue_detail", locale: LanguageManager.shared.currentLocale))
                            .font(TallyType.body(12, weight: .medium))
                            .foregroundStyle(Color.tallyInkFaint)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.tallyInkFaint)
                }
                .padding(TallySpacing.s4)
                .background(Color.tallySurface)
                .clipShape(RoundedRectangle(cornerRadius: TallyRadii.lg, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: TallyRadii.lg, style: .continuous)
                        .stroke(Color.tallyLine, lineWidth: 0.5)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(TallyLocalization.text("report_issue", locale: LanguageManager.shared.currentLocale))
        }
    }

    private func openSupportFeedback() {
        guard MFMailComposeViewController.canSendMail() else {
            showsMailUnavailableAlert = true
            return
        }

        showsFeedbackComposer = true
    }

    private var supportMailSubject: String {
        if TallyLocalization.supportedLanguageCode(for: LanguageManager.shared.currentLocale) == "en" {
            return "Tally Feedback"
        }
        return "Tally 反馈"
    }

    private var supportMailBody: String {
        """
        Hello / 你好，

        问题 / Suggestion:

        复现步骤 / Steps:
        1.
        2.
        3.

        版本 / Version: \(versionText)
        """
    }

    private var acknowledgementsSection: some View {
        AboutSection(
            title: TallyLocalization.text("acknowledgements", locale: LanguageManager.shared.currentLocale),
            rows: [
                AboutInfoRow(
                    icon: "apple.logo",
                    title: TallyLocalization.text("apple_platforms", locale: LanguageManager.shared.currentLocale),
                    detail: TallyLocalization.text("apple_platforms_detail", locale: LanguageManager.shared.currentLocale)
                )
            ]
        )
    }

    private var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        let normalizedVersion = version?.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedBuild = build?.trimmingCharacters(in: .whitespacesAndNewlines)
        let versionValue = normalizedVersion.flatMap { $0.isEmpty ? nil : $0 } ?? "1.0"
        let buildValue = normalizedBuild.flatMap { $0.isEmpty ? nil : $0 } ?? "1"
        return "v\(versionValue) (\(buildValue))"
    }
}

private struct AboutSection: View {
    let title: String
    let rows: [AboutInfoRow]

    var body: some View {
        VStack(alignment: .leading, spacing: TallySpacing.s4) {
            AboutSectionTitle(title)

            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    row
                    if index < rows.count - 1 {
                        Rectangle()
                            .fill(Color.tallyLine)
                            .frame(height: 0.5)
                            .padding(.leading, 56)
                    }
                }
            }
            .background(Color.tallySurface)
            .clipShape(RoundedRectangle(cornerRadius: TallyRadii.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: TallyRadii.lg, style: .continuous)
                    .stroke(Color.tallyLine, lineWidth: 0.5)
            )
        }
    }
}

private struct AboutInfoRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: TallySpacing.s4) {
            AboutIcon(icon)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(TallyType.body(14, weight: .semibold))
                    .foregroundStyle(Color.tallyInk)
                    .fixedSize(horizontal: false, vertical: true)

                Text(detail)
                    .font(TallyType.body(12, weight: .medium))
                    .foregroundStyle(Color.tallyInkFaint)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(TallySpacing.s4)
    }
}

private struct AboutKeyValueRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(TallyType.body(12, weight: .medium))
                .foregroundStyle(Color.tallyInkFaint)

            Spacer(minLength: TallySpacing.s4)

            Text(value)
                .font(TallyType.body(13, weight: .semibold))
                .foregroundStyle(Color.tallyInk)
                .multilineTextAlignment(.trailing)
        }
    }
}

private struct AboutSectionTitle: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(TallyType.body(12, weight: .semibold))
            .foregroundStyle(Color.tallyInkDim)
            .padding(.horizontal, TallySpacing.s1)
    }
}

private struct AboutIcon: View {
    let name: String

    init(_ name: String) {
        self.name = name
    }

    var body: some View {
        Image(systemName: name)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Color.tallyAccent)
            .frame(width: 36, height: 36)
            .background(Color.tallySurface2)
            .clipShape(RoundedRectangle(cornerRadius: TallyRadii.sm, style: .continuous))
    }
}

#Preview("About Tally Light") {
    NavigationStack {
        AboutTallyView()
    }
    .preferredColorScheme(.light)
}

#Preview("About Tally Dark") {
    NavigationStack {
        AboutTallyView()
    }
    .preferredColorScheme(.dark)
}
