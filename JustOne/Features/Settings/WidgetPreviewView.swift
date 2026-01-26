import SwiftUI

struct WidgetPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tabBarVisibility) private var tabBarVisibility

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: JOSpacing.lg) {
                header

                VStack(alignment: .leading, spacing: JOSpacing.sm) {
                    Text("小组件预览")
                        .font(JOTypography.title)
                        .foregroundStyle(JOColors.textPrimary)
                    Text("在桌面长按空白处，点击左上角“+”号，搜索 记一笔 即可添加小组件。")
                        .font(JOTypography.body)
                        .foregroundStyle(JOColors.textSecondary)
                }

                VStack(alignment: .leading, spacing: JOSpacing.md) {
                    Text("小组件 · 快速记账")
                        .font(JOTypography.caption)
                        .foregroundStyle(JOColors.textSecondary)
                    HStack {
                        Spacer()
                        SmallWidgetPreview()
                            .frame(width: 140, height: 140)
                        Spacer()
                    }
                }

                VStack(alignment: .leading, spacing: JOSpacing.md) {
                    Text("中号组件 · 概览与趋势")
                        .font(JOTypography.caption)
                        .foregroundStyle(JOColors.textSecondary)
                    MediumWidgetPreview()
                        .frame(maxWidth: .infinity)
                }

                VStack(alignment: .leading, spacing: JOSpacing.md) {
                    Text("如何添加小组件？")
                        .font(JOTypography.caption)
                        .foregroundStyle(JOColors.textSecondary)
                    InstructionRow(text: "回到手机主屏幕，长按任意空白区域直到图标开始抖动。")
                    InstructionRow(text: "点击左上角的“+”按钮。")
                    InstructionRow(text: "在搜索框输入 记一笔 并选择喜欢的样式。")
                }
            }
            .padding(.horizontal, JOSpacing.lg)
            .padding(.top, JOSpacing.lg)
            .padding(.bottom, JOSpacing.xl)
        }
        .background(JOColors.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            tabBarVisibility?.setVisible(false)
        }
    }

    private var header: some View {
        JOHeaderBar(
            title: "桌面小组件",
            titleFont: JOTypography.headline,
            titleColor: JOColors.profileRowTitle
        ) {
            dismiss()
        }
    }
}

private struct SmallWidgetPreview: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(JOColors.surface.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(JOColors.cardBorder, lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(JOColors.accent.opacity(0.15))
                        .frame(width: 20, height: 20)
                        .overlay(
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(JOColors.accent)
                        )
                    Text("今日支出")
                        .font(JOTypography.caption)
                        .foregroundStyle(JOColors.textSecondary)
                }

                Text("¥88.5")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(JOColors.textPrimary)

                Capsule()
                    .fill(JOColors.accent)
                    .frame(width: 26, height: 4)

                Spacer(minLength: 0)

                HStack {
                    Spacer()
                    Circle()
                        .fill(JOColors.accent)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(JOColors.accentForeground)
                        )
                }
            }
            .padding(12)
        }
        .frame(height: 140)
    }
}

private struct MediumWidgetPreview: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(JOColors.surface.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(JOColors.cardBorder, lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("本月支出")
                            .font(JOTypography.caption)
                            .foregroundStyle(JOColors.textSecondary)
                        Text("¥2,340.00")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(JOColors.textPrimary)
                    }
                    Spacer()
                    HStack(spacing: 8) {
                        Circle()
                            .fill(JOColors.profileRowBackground)
                            .frame(width: 26, height: 26)
                            .overlay(
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(JOColors.textSecondary)
                            )
                        Circle()
                            .fill(JOColors.accent)
                            .frame(width: 26, height: 26)
                            .overlay(
                                Image(systemName: "plus")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(JOColors.accentForeground)
                            )
                    }
                }

                WidgetLinePreview()
                    .frame(height: 42)

                HStack {
                    ForEach([1, 5, 10, 15, 20, 25, 30], id: \.self) { day in
                        Text("\(day)")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(JOColors.textSecondary.opacity(0.7))
                        if day != 30 { Spacer(minLength: 0) }
                    }
                }
            }
            .padding(16)
        }
        .frame(height: 140)
    }
}

private struct WidgetLinePreview: View {
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let points: [CGPoint] = [
                CGPoint(x: 0, y: height * 0.9),
                CGPoint(x: width * 0.35, y: height * 0.9),
                CGPoint(x: width * 0.55, y: height * 0.4),
                CGPoint(x: width * 0.7, y: height * 0.15),
                CGPoint(x: width, y: height * 0.8)
            ]

            Path { path in
                path.move(to: points[0])
                for index in 1..<points.count {
                    let prev = points[index - 1]
                    let current = points[index]
                    let mid = CGPoint(x: (prev.x + current.x) / 2, y: (prev.y + current.y) / 2)
                    path.addQuadCurve(to: mid, control: prev)
                    if index == points.count - 1 {
                        path.addQuadCurve(to: current, control: current)
                    }
                }
            }
            .stroke(JOColors.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
        }
    }
}

private struct InstructionRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(JOColors.textSecondary.opacity(0.5))
                .frame(width: 6, height: 6)
                .padding(.top, 6)
            Text(text)
                .font(JOTypography.body)
                .foregroundStyle(JOColors.textSecondary)
        }
    }
}

#Preview {
    NavigationStack {
        WidgetPreviewView()
    }
    .environment(\.appEnvironment, .preview)
}
