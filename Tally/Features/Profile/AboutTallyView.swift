import SwiftUI

struct AboutTallyView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tabBarVisibility) private var tabBarVisibility

    private let onBack: (() -> Void)?
    private let supportURL = URL(string: "https://github.com/lynxlangya/Tally/issues")!

    init(onBack: (() -> Void)? = nil) {
        self.onBack = onBack
    }

    var body: some View {
        ZStack {
            Color.tallyBg.ignoresSafeArea()

            VStack(spacing: 0) {
                TallyNavHeader(title: "关于 Tally", onBack: close)

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

                    Text("单币种本地记账")
                        .font(TallyType.body(13, weight: .medium))
                        .foregroundStyle(Color.tallyInkDim)
                }

                Spacer(minLength: 0)
            }

            AboutKeyValueRow(title: "版本", value: versionText)
            AboutKeyValueRow(title: "数据范围", value: "账单、分类、定时记账、Widget 快照")
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
            title: "隐私政策",
            rows: [
                AboutInfoRow(
                    icon: "lock.fill",
                    title: "默认留在本机",
                    detail: "账单、分类、偏好设置和头像保存在本机；Widget 仅读取 App Group 中的摘要快照。"
                ),
                AboutInfoRow(
                    icon: "network.slash",
                    title: "不做联网分析",
                    detail: "当前版本没有第三方分析、广告追踪或远程账号同步。"
                ),
                AboutInfoRow(
                    icon: "bell.fill",
                    title: "通知按需开启",
                    detail: "每日提醒只在你手动开启后申请系统通知权限。"
                )
            ]
        )
    }

    private var dataSection: some View {
        AboutSection(
            title: "数据与备份",
            rows: [
                AboutInfoRow(
                    icon: "externaldrive.fill",
                    title: "手动导入导出",
                    detail: "你可以在“导入与导出”中生成 CSV 或 JSON 备份文件。"
                ),
                AboutInfoRow(
                    icon: "photo.fill",
                    title: "头像选择",
                    detail: "账号头像来自系统照片选择器，图片数据只用于本机展示。"
                )
            ]
        )
    }

    private var supportSection: some View {
        VStack(alignment: .leading, spacing: TallySpacing.s4) {
            AboutSectionTitle("支持")

            Link(destination: supportURL) {
                HStack(spacing: TallySpacing.s4) {
                    AboutIcon("questionmark.circle.fill")

                    VStack(alignment: .leading, spacing: 3) {
                        Text("反馈问题")
                            .font(TallyType.body(14, weight: .semibold))
                            .foregroundStyle(Color.tallyInk)
                        Text("通过 GitHub Issues 提交问题和建议")
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
            .accessibilityLabel("反馈问题")
        }
    }

    private var acknowledgementsSection: some View {
        AboutSection(
            title: "致谢",
            rows: [
                AboutInfoRow(
                    icon: "apple.logo",
                    title: "Apple 平台技术",
                    detail: "Tally 使用 SwiftUI、Core Data 与 WidgetKit 构建。"
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
