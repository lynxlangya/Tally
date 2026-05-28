import SwiftUI
import UIKit

struct ThemeSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tabBarVisibility) private var tabBarVisibility
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var iconErrorMessage: String?

    private var settings: ThemeSettings { themeManager.settings }

    var body: some View {
        ZStack {
            Color.tallyBg.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, TallySpacing.s6)
                    .padding(.top, TallySpacing.s4)
                    .padding(.bottom, TallySpacing.s6)

                ScrollView {
                    VStack(spacing: 28) {
                        previewCard
                        appearanceSection
                        accentSection
                        appIconSection
                        detailSection
                        resetButton
                    }
                    .padding(.horizontal, TallySpacing.s6)
                    .padding(.bottom, TallySpacing.s9)
                }
                .scrollIndicators(.hidden)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .applyThemePreview(settings: settings)
        .alert("图标暂时无法切换", isPresented: iconErrorBinding) {
            Button("知道了", role: .cancel) { }
        } message: {
            Text(iconErrorMessage ?? "请稍后再试。")
        }
        .onAppear {
            tabBarVisibility?.setVisible(false)
        }
    }

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.tallyInk)
                    .frame(width: 36, height: 36)
                    .background(Color.tallySurface2)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("返回")

            Spacer()

            Text("主题与外观")
                .font(TallyType.display(18, weight: .semibold))
                .foregroundStyle(Color.tallyInk)

            Spacer()

            Color.clear
                .frame(width: 36, height: 36)
        }
    }

    private var previewCard: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                Text("预览 · 本月 5 月")
                    .font(TallyType.body(12, weight: .semibold))
                    .foregroundStyle(Color.tallyInkFaint)

                Spacer()

                Text(settings.accent.name)
                    .font(TallyType.body(11, weight: .medium))
                    .foregroundStyle(Color.tallyInkDim)

                Circle()
                    .fill(settings.accent.color)
                    .frame(width: 10, height: 10)
            }
            .padding(.horizontal, TallySpacing.s5)
            .frame(height: 56)

            DividerLine()

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("¥")
                    .font(numberFont(size: 34, weight: .regular))
                    .foregroundStyle(Color.tallyInkFaint)
                Text(primaryAmountText)
                    .font(numberFont(size: 48, weight: .semibold))
                    .foregroundStyle(Color.tallyInk)
                Text(decimalAmountText)
                    .font(numberFont(size: 24, weight: .medium))
                    .foregroundStyle(Color.tallyInkFaint)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, TallySpacing.s5)
            .frame(height: 76)

            DividerLine()
                .padding(.horizontal, TallySpacing.s5)

            HStack(alignment: .bottom) {
                Sparkline(
                    data: [2, 3, 4, 4, 2, 7, 1, 5],
                    color: settings.accent.color,
                    fill: false,
                    dot: true,
                    width: 104,
                    height: 42
                )

                Spacer()

                Button {
                    select {}
                } label: {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(.white.opacity(0.16))
                            .frame(width: 24, height: 24)
                            .overlay(
                                TallyMark(size: 12, variant: .one, color: .white, strokeWidth: 1.8)
                            )

                        Text("记一笔")
                            .font(TallyType.body(14, weight: .semibold))
                    }
                    .foregroundStyle(Color.tallyAccentInk)
                    .padding(.leading, 10)
                    .padding(.trailing, 16)
                    .frame(height: 44)
                    .background(settings.accent.color)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("预览记一笔")
            }
            .padding(.horizontal, TallySpacing.s5)
            .frame(height: 86)
        }
        .background(Color.tallySurface)
        .clipShape(RoundedRectangle(cornerRadius: TallyRadii.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: TallyRadii.xl, style: .continuous)
                .stroke(Color.tallyLine, lineWidth: 0.5)
        )
        .tallyShadow(.shadow2)
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: TallySpacing.s4) {
            SectionTitle(title: "皮肤", trailing: settings.appearance.title)

            GeometryReader { proxy in
                let spacing: CGFloat = 10
                let width = (proxy.size.width - spacing * 2) / 3

                HStack(spacing: spacing) {
                    ForEach(AppearanceMode.allCases) { mode in
                        AppearanceCard(
                            mode: mode,
                            isSelected: settings.appearance == mode,
                            accent: settings.accent.color,
                            width: width
                        ) {
                            select {
                                themeManager.setAppearance(mode)
                            }
                        }
                    }
                }
            }
            .frame(height: 146)
        }
    }

    private var accentSection: some View {
        VStack(alignment: .leading, spacing: TallySpacing.s4) {
            SectionTitle(title: "SIGNATURE 色", trailing: settings.accent.displayName)

            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    ForEach(themeManager.accentOptions) { option in
                        AccentSwatch(
                            option: option,
                            isSelected: settings.accent == option
                        ) {
                            select {
                                themeManager.setAccent(option)
                            }
                        }
                    }
                }
                .padding(.horizontal, TallySpacing.s4)
                .padding(.top, TallySpacing.s5)
                .padding(.bottom, TallySpacing.s4)

                DividerLine()
                    .padding(.horizontal, TallySpacing.s4)

                HStack {
                    Text("FAB · 收入 · 强调")
                        .font(TallyType.body(13, weight: .medium))
                        .foregroundStyle(Color.tallyInkDim)
                    Spacer()
                    Text(settings.accent.hexText)
                        .font(TallyType.body(12, weight: .medium))
                        .foregroundStyle(Color.tallyInkFaint)
                }
                .padding(.horizontal, TallySpacing.s4)
                .frame(height: 54)
            }
            .background(Color.tallySurface)
            .clipShape(RoundedRectangle(cornerRadius: TallyRadii.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: TallyRadii.lg, style: .continuous)
                    .stroke(Color.tallyLine, lineWidth: 0.5)
            )
        }
    }

    private var appIconSection: some View {
        VStack(alignment: .leading, spacing: TallySpacing.s4) {
            SectionTitle(title: "APP 图标", trailing: "点选后同步主屏图标")

            HStack(spacing: TallySpacing.s5) {
                ForEach(ThemeAppIconOption.allCases) { option in
                    AppIconChoice(
                        option: option,
                        isSelected: settings.appIcon == option,
                        accent: settings.accent.color
                    ) {
                        select {
                            setAppIcon(option)
                        }
                    }
                }
            }
        }
    }

    private var detailSection: some View {
        VStack(alignment: .leading, spacing: TallySpacing.s4) {
            SectionTitle(title: "细节", trailing: nil)

            VStack(spacing: 0) {
                DetailToggleRow(
                    title: "减少动效",
                    subtitle: "关闭弹簧与过渡",
                    isOn: Binding(
                        get: { settings.reduceMotion },
                        set: { themeManager.setReduceMotion($0) }
                    ),
                    accent: settings.accent.color
                )

                DividerLine()
                    .padding(.leading, TallySpacing.s4)

                DetailToggleRow(
                    title: "触感反馈",
                    subtitle: "记一笔与拨号盘时轻触",
                    isOn: Binding(
                        get: { settings.hapticFeedback },
                        set: { themeManager.setHapticFeedback($0) }
                    ),
                    accent: settings.accent.color
                )
            }
            .background(Color.tallySurface)
            .clipShape(RoundedRectangle(cornerRadius: TallyRadii.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: TallyRadii.lg, style: .continuous)
                    .stroke(Color.tallyLine, lineWidth: 0.5)
            )
        }
    }

    private var resetButton: some View {
        Button {
            select {
                resetToDefaults()
            }
        } label: {
            HStack(spacing: TallySpacing.s3) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 14, weight: .semibold))
                Text("恢复默认 · \(ThemeManager.defaultAppearance.title) \(themeManager.defaultAccent.name)")
                    .font(TallyType.body(14, weight: .semibold))
            }
            .foregroundStyle(Color.tallyInkDim)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Color.tallyBg)
            .clipShape(RoundedRectangle(cornerRadius: TallyRadii.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: TallyRadii.lg, style: .continuous)
                    .stroke(Color.tallyLine, style: StrokeStyle(lineWidth: 0.75, dash: [3, 3]))
            )
        }
        .buttonStyle(.plain)
    }

    private var primaryAmountText: String {
        "6,421"
    }

    private var decimalAmountText: String {
        ".88"
    }

    private func numberFont(size: CGFloat, weight: Font.Weight) -> Font {
        TallyType.display(size, weight: weight)
    }

    private func select(_ action: () -> Void) {
        if settings.hapticFeedback {
            UISelectionFeedbackGenerator().selectionChanged()
        }

        if settings.reduceMotion {
            action()
        } else {
            withAnimation(.tallyBase) {
                action()
            }
        }
    }

    private var iconErrorBinding: Binding<Bool> {
        Binding(
            get: { iconErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    iconErrorMessage = nil
                }
            }
        )
    }

    private func setAppIcon(_ option: ThemeAppIconOption) {
        guard UIApplication.shared.supportsAlternateIcons else {
            themeManager.setAppIcon(option)
            return
        }

        UIApplication.shared.setAlternateIconName(option.alternateIconName) { error in
            Task { @MainActor in
                if let error {
                    iconErrorMessage = error.localizedDescription
                } else {
                    themeManager.setAppIcon(option)
                }
            }
        }
    }

    private func resetToDefaults() {
        guard UIApplication.shared.supportsAlternateIcons else {
            themeManager.resetToDefaults()
            return
        }

        UIApplication.shared.setAlternateIconName(ThemeManager.defaultAppIcon.alternateIconName) { error in
            Task { @MainActor in
                if let error {
                    iconErrorMessage = error.localizedDescription
                } else {
                    themeManager.resetToDefaults()
                }
            }
        }
    }
}

private extension View {
    @ViewBuilder
    func applyThemePreview(settings: ThemeSettings) -> some View {
        if let colorScheme = settings.appearance.preferredColorScheme {
            self
                .environment(\.colorScheme, colorScheme)
                .preferredColorScheme(colorScheme)
        } else {
            self.preferredColorScheme(nil)
        }
    }
}

private struct SectionTitle: View {
    let title: String
    let trailing: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(TallyType.body(13, weight: .semibold))
                .foregroundStyle(Color.tallyInkDim)
                .tracking(1.8)

            Spacer()

            if let trailing {
                Text(trailing)
                    .font(TallyType.body(12, weight: .medium))
                    .foregroundStyle(Color.tallyInkFaint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
        }
        .padding(.horizontal, TallySpacing.s1)
    }
}

private struct AppearanceCard: View {
    let mode: AppearanceMode
    let isSelected: Bool
    let accent: Color
    let width: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: TallySpacing.s3) {
                preview
                    .frame(width: width, height: 110)
                    .clipShape(RoundedRectangle(cornerRadius: TallyRadii.lg, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: TallyRadii.lg, style: .continuous)
                            .stroke(isSelected ? accent : Color.tallyLineHi, lineWidth: isSelected ? 1.6 : 0.7)
                    )
                    .overlay(alignment: .topTrailing) {
                        Circle()
                            .fill(accent)
                            .frame(width: 8, height: 8)
                            .padding(10)
                    }

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(mode.title)
                        .font(TallyType.body(13, weight: .semibold))
                        .foregroundStyle(isSelected ? Color.tallyInk : Color.tallyInkDim)
                    Text(mode.subtitle)
                        .font(TallyType.body(11, weight: .medium))
                        .foregroundStyle(Color.tallyInkFaint)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(mode.title) \(mode.subtitle)")
        .tallySelectedAccessibility(isSelected)
    }

    @ViewBuilder
    private var preview: some View {
        switch mode {
        case .dark:
            cardSurface(Color(red: 17 / 255, green: 18 / 255, blue: 16 / 255), ink: .white.opacity(0.9))
        case .light:
            cardSurface(Color(red: 255 / 255, green: 252 / 255, blue: 245 / 255), ink: Color.tallyInk)
        case .system:
            ZStack {
                cardSurface(Color(red: 17 / 255, green: 18 / 255, blue: 16 / 255), ink: .white.opacity(0.88))
                Path { path in
                    path.move(to: CGPoint(x: width * 0.72, y: 0))
                    path.addLine(to: CGPoint(x: width, y: 0))
                    path.addLine(to: CGPoint(x: width, y: 110))
                    path.addLine(to: CGPoint(x: width * 0.62, y: 110))
                    path.closeSubpath()
                }
                .fill(Color(red: 255 / 255, green: 252 / 255, blue: 245 / 255))
            }
        }
    }

    private func cardSurface(_ background: Color, ink: Color) -> some View {
        ZStack(alignment: .leading) {
            background

            VStack(alignment: .leading, spacing: TallySpacing.s3) {
                Capsule()
                    .fill(ink.opacity(0.24))
                    .frame(width: 22, height: 4)
                Spacer()
                Text(MoneyFormatter.wholeYuanString(fromCents: 642_100))
                    .font(TallyType.num(16, weight: .semibold))
                    .foregroundStyle(ink)
                Rectangle()
                    .fill(ink.opacity(0.14))
                    .frame(height: 0.5)
                HStack(spacing: 3) {
                    ForEach(0..<4, id: \.self) { _ in
                        Capsule()
                            .fill(ink.opacity(0.18))
                            .frame(width: 3, height: 8)
                    }
                    Rectangle()
                        .fill(accent)
                        .frame(width: 12, height: 2)
                        .rotationEffect(.degrees(-18))
                }
            }
            .padding(12)
        }
    }
}

private struct AccentSwatch: View {
    let option: AccentOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Circle()
                    .fill(option.color)
                    .frame(width: 38, height: 38)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? option.color : Color.tallyLineHi, lineWidth: isSelected ? 2 : 0.7)
                            .padding(isSelected ? -5 : 0)
                    )
                    .overlay {
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.black.opacity(option.id == "moon" ? 0.72 : 0.88))
                        }
                    }

                Text(option.name)
                    .font(TallyType.body(11, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? Color.tallyInk : Color.tallyInkFaint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(option.displayName)
        .tallySelectedAccessibility(isSelected)
    }
}

private struct AppIconChoice: View {
    let option: ThemeAppIconOption
    let isSelected: Bool
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                icon
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: Color.tallyInk.opacity(0.08), radius: 14, x: 0, y: 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(isSelected ? accent : Color.tallyLineHi, lineWidth: isSelected ? 1.8 : 0.6)
                            .padding(isSelected ? -4 : 0)
                    )

                Text(option.title)
                    .font(TallyType.body(12, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? Color.tallyInk : Color.tallyInkFaint)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(option.title)
        .tallySelectedAccessibility(isSelected)
    }

    @ViewBuilder
    private var icon: some View {
        switch option {
        case .vermilion:
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(accent)
                .overlay(TallyMark(size: 34, variant: .five, color: .white, strokeWidth: 3))
        case .moon:
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.tallySurface)
                .overlay(TallyMark(size: 34, variant: .five, color: accent, strokeWidth: 3))
        case .ink:
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.tallyInk, Color.tallyInk.opacity(0.86)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(TallyMark(size: 30, variant: .one, color: .white, strokeWidth: 4))
        case .inkNote:
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.tallyInk, Color.tallyInk.opacity(0.86)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(TallyMark(size: 34, variant: .five, color: accent, strokeWidth: 3))
                .overlay(alignment: .bottomTrailing) {
                    Text("记")
                        .font(TallyType.body(10, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 18, height: 18)
                        .background(accent)
                        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                        .padding(5)
                }
        }
    }
}

private struct DetailToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let accent: Color

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(TallyType.body(15, weight: .semibold))
                    .foregroundStyle(Color.tallyInk)
                Text(subtitle)
                    .font(TallyType.body(12, weight: .medium))
                    .foregroundStyle(Color.tallyInkFaint)
            }
        }
        .toggleStyle(TallyThemeToggleStyle(accent: accent))
        .padding(.horizontal, TallySpacing.s4)
        .frame(height: 66)
    }
}

private struct TallyThemeToggleStyle: ToggleStyle {
    let accent: Color

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label

            Spacer()

            Button {
                withAnimation(.tallyFast) {
                    configuration.isOn.toggle()
                }
            } label: {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(configuration.isOn ? accent : Color.tallyInkGhost.opacity(0.22))
                    .frame(width: 46, height: 28)
                    .overlay(
                        Circle()
                            .fill(Color.tallySurface)
                            .frame(width: 22, height: 22)
                            .offset(x: configuration.isOn ? 9 : -9)
                            .shadow(color: Color.tallyInk.opacity(0.08), radius: 2, x: 0, y: 1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.tallyLineHi, lineWidth: 0.5)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(configuration.isOn ? "已开启" : "已关闭")
        }
    }
}

private struct DividerLine: View {
    var body: some View {
        Rectangle()
            .fill(Color.tallyLine)
            .frame(height: 0.5)
    }
}

private extension View {
    @ViewBuilder
    func tallySelectedAccessibility(_ isSelected: Bool) -> some View {
        if isSelected {
            accessibilityAddTraits(.isSelected)
        } else {
            self
        }
    }
}

#Preview("Theme Settings Light") {
    NavigationStack {
        ThemeSettingsView()
    }
    .environment(\.appEnvironment, .preview)
    .preferredColorScheme(.light)
}

#Preview("Theme Settings Dark") {
    NavigationStack {
        ThemeSettingsView()
    }
    .environment(\.appEnvironment, .preview)
    .preferredColorScheme(.dark)
}
