import SwiftUI

struct WidgetPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tabBarVisibility) private var tabBarVisibility

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LegacySpacing.lg) {
                header

                VStack(alignment: .leading, spacing: LegacySpacing.sm) {
                    Text("小组件预览")
                        .font(LegacyTypography.title)
                        .foregroundStyle(LegacyColors.textPrimary)
                    Text("在桌面长按空白处，点击左上角“+”号，搜索 记一笔 即可添加小组件。")
                        .font(LegacyTypography.body)
                        .foregroundStyle(LegacyColors.textSecondary)
                }
                .padding(.bottom, LegacySpacing.md)

                VStack(alignment: .leading, spacing: LegacySpacing.lg) {
                    SectionLabel(text: "小组件 · 快速记账")
                    HStack {
                        Spacer()
                        ZStack {
                            GlowOrb()
                                .frame(width: 160, height: 160)
                            SmallWidgetPreview()
                                .frame(width: 140, height: 140)
                        }
                        Spacer()
                    }
                }
                .padding(.vertical, LegacySpacing.sm)

                VStack(alignment: .leading, spacing: LegacySpacing.lg) {
                    SectionLabel(text: "中号组件 · 概览与趋势")
                    ZStack {
                        GlowOrb()
                            .frame(height: 150)
                            .opacity(0.6)
                        MediumWidgetPreview()
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, LegacySpacing.sm)

                VStack(alignment: .leading, spacing: LegacySpacing.md) {
                    SectionLabel(text: "如何添加小组件？")
                    InstructionRow(text: "回到手机主屏幕，长按任意空白区域直到图标开始抖动。")
                    InstructionRow(text: "点击左上角的“+”按钮。")
                    InstructionRow(text: "在搜索框输入 记一笔 并选择喜欢的样式。")
                }
                .padding(.vertical, LegacySpacing.sm)
            }
            .padding(.horizontal, LegacySpacing.lg)
            .padding(.top, LegacySpacing.lg)
            .padding(.bottom, LegacySpacing.xl)
        }
        .background(WidgetPreviewBackground().ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            tabBarVisibility?.setVisible(false)
        }
    }

    private var header: some View {
        LegacyHeaderBar(
            title: "桌面小组件",
            titleFont: LegacyTypography.headline,
            titleColor: LegacyColors.profileRowTitle
        ) {
            dismiss()
        }
    }
}

private struct SmallWidgetPreview: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            LegacyColors.surface.opacity(0.95),
                            LegacyColors.surface.opacity(0.74)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(LegacyColors.cardBorder.opacity(0.25), lineWidth: 0.7)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.12),
                                    Color.clear,
                                    Color.black.opacity(0.22)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                        .blendMode(.overlay)
                )
                .shadow(color: LegacyColors.accent.opacity(0.1), radius: 10, x: 0, y: 6)
                .rotation3DEffect(.degrees(4), axis: (x: 1, y: -0.2, z: 0))

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(LegacyColors.accent.opacity(0.2))
                        .frame(width: 20, height: 20)
                        .overlay(
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(LegacyColors.accent)
                        )
                    Text("今日支出")
                        .font(LegacyTypography.caption)
                        .foregroundStyle(LegacyColors.textSecondary)
                }

                Text("¥88.5")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(LegacyColors.textPrimary)

                Spacer().frame(height: 2)

                Capsule()
                    .fill(LegacyColors.accent)
                    .frame(width: 26, height: 4)

                Spacer(minLength: 0)

                HStack {
                    Spacer()
                    Circle()
                        .fill(LegacyColors.accent)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(LegacyColors.accentForeground)
                        )
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 12)
        }
        .frame(height: 140)
    }
}

private struct MediumWidgetPreview: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            LegacyColors.surface.opacity(0.95),
                            LegacyColors.surface.opacity(0.68)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(LegacyColors.cardBorder.opacity(0.25), lineWidth: 0.7)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.12),
                                    Color.clear,
                                    Color.black.opacity(0.22)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                        .blendMode(.overlay)
                )
                .shadow(color: LegacyColors.accent.opacity(0.1), radius: 12, x: 0, y: 7)
                .rotation3DEffect(.degrees(3), axis: (x: 1, y: -0.15, z: 0))

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("本月支出")
                            .font(LegacyTypography.caption)
                            .foregroundStyle(LegacyColors.textSecondary)
                        Text("¥2,340.00")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(LegacyColors.textPrimary)
                    }
                    Spacer()
                    HStack(spacing: 8) {
                        Circle()
                            .fill(LegacyColors.profileRowBackground)
                            .frame(width: 26, height: 26)
                            .overlay(
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(LegacyColors.textSecondary)
                            )
                        Circle()
                            .fill(LegacyColors.accent)
                            .frame(width: 26, height: 26)
                            .overlay(
                                Image(systemName: "plus")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(LegacyColors.accentForeground)
                            )
                    }
                }

                WidgetLinePreview()
                    .frame(height: 42)

                HStack {
                    ForEach([1, 5, 10, 15, 20, 25, 30], id: \.self) { day in
                        Text("\(day)")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(LegacyColors.textSecondary.opacity(0.7))
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

            let linePath = Path { path in
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

            linePath
                .stroke(LegacyColors.accent, style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))
                .shadow(color: LegacyColors.accent.opacity(0.4), radius: 6, x: 0, y: 4)

            let fillPath = Path { path in
                path.addPath(linePath)
                path.addLine(to: CGPoint(x: width, y: height))
                path.addLine(to: CGPoint(x: 0, y: height))
                path.closeSubpath()
            }

            fillPath
                .fill(
                    LinearGradient(
                        colors: [
                            LegacyColors.accent.opacity(0.25),
                            LegacyColors.accent.opacity(0.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
    }
}

private struct SectionLabel: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Capsule()
                .fill(LegacyColors.accent.opacity(0.6))
                .frame(width: 14, height: 4)
            Text(text)
                .font(LegacyTypography.caption)
                .foregroundStyle(LegacyColors.textSecondary)
        }
    }
}

private struct GlowOrb: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(LegacyColors.accent.opacity(0.25))
                .blur(radius: 28)
            Circle()
                .fill(LegacyColors.accent.opacity(0.12))
                .blur(radius: 50)
        }
    }
}

private struct WidgetPreviewBackground: View {
    var body: some View {
        ZStack {
            LegacyColors.background
            RadialGradient(
                colors: [
                    LegacyColors.accent.opacity(0.12),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 40,
                endRadius: 220
            )
            RadialGradient(
                colors: [
                    LegacyColors.accent.opacity(0.08),
                    .clear
                ],
                center: .bottomLeading,
                startRadius: 30,
                endRadius: 240
            )
        }
    }
}

private struct InstructionRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(LegacyColors.textSecondary.opacity(0.5))
                .frame(width: 6, height: 6)
                .padding(.top, 6)
            Text(text)
                .font(LegacyTypography.body)
                .foregroundStyle(LegacyColors.textSecondary)
        }
    }
}

#Preview {
    NavigationStack {
        WidgetPreviewView()
    }
    .environment(\.appEnvironment, .preview)
}
