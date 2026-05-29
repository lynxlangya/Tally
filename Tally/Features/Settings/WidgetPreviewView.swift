import SwiftUI

struct WidgetPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tabBarVisibility) private var tabBarVisibility
    @State private var snapshot = WidgetPreviewSnapshot.sample

    var body: some View {
        ZStack {
            Color.tallyBg.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, TallySpacing.s6)
                    .padding(.top, TallySpacing.s4)
                    .padding(.bottom, TallySpacing.s6)

                ScrollView {
                    VStack(alignment: .leading, spacing: TallySpacing.s8) {
                        intro
                        widgetGallery
                        addPath
                    }
                    .padding(.horizontal, TallySpacing.s6)
                    .padding(.bottom, TallySpacing.s9)
                }
                .scrollIndicators(.hidden)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            tabBarVisibility?.setVisible(false)
            snapshot = WidgetPreviewSnapshot.current()
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
            .accessibilityLabel(TallyLocalization.text("back", locale: LanguageManager.shared.currentLocale))

            Spacer()

            Text(TallyLocalization.text(.widget, locale: LanguageManager.shared.currentLocale))
                .font(TallyType.display(18, weight: .semibold))
                .foregroundStyle(Color.tallyInk)

            Spacer()

            Color.clear
                .frame(width: 36, height: 36)
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: TallySpacing.s4) {
            Eyebrow("widget kit", color: .tallyAccent)

            HStack(alignment: .bottom, spacing: TallySpacing.s4) {
                VStack(alignment: .leading, spacing: TallySpacing.s2) {
                    Text(TallyLocalization.text("widget_intro_title", locale: LanguageManager.shared.currentLocale))
                        .font(TallyType.display(32, weight: .semibold))
                        .foregroundStyle(Color.tallyInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.74)

                    Text(TallyLocalization.text("widget_intro_subtitle", locale: LanguageManager.shared.currentLocale))
                        .font(TallyType.body(14, weight: .medium))
                        .foregroundStyle(Color.tallyInkDim)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: TallySpacing.s2)

                WidgetCountBadge(count: 2)
            }
        }
    }

    private var widgetGallery: some View {
        VStack(alignment: .leading, spacing: TallySpacing.s7) {
            WidgetShowcase(
                eyebrow: "small",
                title: TallyLocalization.text("widget_quick_entry_title", locale: LanguageManager.shared.currentLocale),
                subtitle: TallyLocalization.text("widget_quick_entry_subtitle", locale: LanguageManager.shared.currentLocale),
                width: 158,
                height: 158
            ) {
                QuickEntryWidgetCard(model: snapshot.quickEntry)
            }

            WidgetShowcase(
                eyebrow: "medium",
                title: TallyLocalization.text("widget_summary_title", locale: LanguageManager.shared.currentLocale),
                subtitle: TallyLocalization.text("widget_summary_subtitle", locale: LanguageManager.shared.currentLocale),
                width: 338,
                height: 158
            ) {
                SummaryTrendWidgetCard(model: snapshot.summary)
            }
        }
    }

    private var addPath: some View {
        VStack(alignment: .leading, spacing: TallySpacing.s4) {
            SectionHeader(
                title: TallyLocalization.text("widget_add_path", locale: LanguageManager.shared.currentLocale),
                trailing: TallyLocalization.text("widget_home_screen", locale: LanguageManager.shared.currentLocale)
            )

            VStack(spacing: 0) {
                AddStepRow(
                    index: 1,
                    title: TallyLocalization.text("widget_step_hold", locale: LanguageManager.shared.currentLocale),
                    detail: TallyLocalization.text("widget_step_hold_detail", locale: LanguageManager.shared.currentLocale)
                )
                DividerLine()
                    .padding(.leading, 54)
                AddStepRow(
                    index: 2,
                    title: TallyLocalization.text("widget_step_plus", locale: LanguageManager.shared.currentLocale),
                    detail: TallyLocalization.text("widget_step_plus_detail", locale: LanguageManager.shared.currentLocale)
                )
                DividerLine()
                    .padding(.leading, 54)
                AddStepRow(
                    index: 3,
                    title: TallyLocalization.text("widget_step_size", locale: LanguageManager.shared.currentLocale),
                    detail: TallyLocalization.text("widget_step_size_detail", locale: LanguageManager.shared.currentLocale)
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
}

private struct WidgetShowcase<Content: View>: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    let width: CGFloat
    let height: CGFloat
    let content: () -> Content

    init(
        eyebrow: String,
        title: String,
        subtitle: String,
        width: CGFloat,
        height: CGFloat,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
        self.width = width
        self.height = height
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TallySpacing.s4) {
            SectionHeader(title: title, trailing: eyebrow)

            Text(subtitle)
                .font(TallyType.body(12, weight: .medium))
                .foregroundStyle(Color.tallyInkFaint)

            HStack {
                Spacer(minLength: 0)
                WidgetDeviceFrame(width: width, height: height) {
                    content()
                }
                Spacer(minLength: 0)
            }
        }
    }
}

private struct WidgetDeviceFrame<Content: View>: View {
    let width: CGFloat
    let height: CGFloat
    let content: () -> Content

    init(width: CGFloat, height: CGFloat, @ViewBuilder content: @escaping () -> Content) {
        self.width = width
        self.height = height
        self.content = content
    }

    var body: some View {
        GeometryReader { proxy in
            let availableWidth = max(proxy.size.width, 1)
            let scale = min(1, availableWidth / width)

            framedContent
                .scaleEffect(scale, anchor: .top)
                .frame(width: width * scale, height: height * scale, alignment: .top)
                .frame(maxWidth: .infinity, alignment: .top)
                .padding(.vertical, TallySpacing.s2)
        }
        .frame(height: height + TallySpacing.s4)
    }

    private var framedContent: some View {
        content()
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.tallyInk.opacity(0.05), lineWidth: 1)
                    .padding(-1)
            )
            .shadow(color: Color.tallyInk.opacity(0.10), radius: 24, x: 0, y: 16)
            .shadow(color: Color.tallyAccent.opacity(0.16), radius: 32, x: 0, y: 18)
    }
}

private struct WidgetCountBadge: View {
    let count: Int

    var body: some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(TallyType.num(24, weight: .semibold))
                .foregroundStyle(Color.tallyInk)
            Text(TallyLocalization.text("widget_count_unit", locale: LanguageManager.shared.currentLocale))
                .font(TallyType.body(11, weight: .semibold))
                .foregroundStyle(Color.tallyInkFaint)
        }
        .frame(width: 58, height: 58)
        .background(Color.tallySurface)
        .clipShape(RoundedRectangle(cornerRadius: TallyRadii.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: TallyRadii.lg, style: .continuous)
                .stroke(Color.tallyLine, lineWidth: 0.5)
        )
    }
}

private struct SectionHeader: View {
    let title: String
    let trailing: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(TallyType.body(15, weight: .semibold))
                .foregroundStyle(Color.tallyInk)

            Spacer()

            Text(trailing)
                .font(TallyType.body(11, weight: .semibold))
                .tracking(11 * 0.06)
                .textCase(.uppercase)
                .foregroundStyle(Color.tallyInkFaint)
        }
    }
}

private struct AddStepRow: View {
    let index: Int
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: TallySpacing.s3) {
            Text("\(index)")
                .font(TallyType.num(13, weight: .semibold))
                .foregroundStyle(Color.tallyAccentInk)
                .frame(width: 30, height: 30)
                .background(Color.tallyAccent)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(TallyType.body(14, weight: .semibold))
                    .foregroundStyle(Color.tallyInk)
                Text(detail)
                    .font(TallyType.body(12, weight: .medium))
                    .foregroundStyle(Color.tallyInkFaint)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, TallySpacing.s4)
        .frame(height: 64)
    }
}

private struct DividerLine: View {
    var body: some View {
        Rectangle()
            .fill(Color.tallyLine)
            .frame(height: 0.5)
    }
}

private enum WidgetPreviewSnapshot {
    static func current() -> WidgetSnapshot {
        let live = WidgetDataStore.loadSnapshot()
        return live.hasDisplayData ? live : sample
    }

    static let sample = WidgetSnapshot(
        updatedAt: Date(timeIntervalSinceReferenceDate: 800_000_000),
        quickEntry: QuickEntryWidgetModel(
            todayExpenseCents: 42600,
            todayEntryCount: 4,
            yesterdayExpenseCents: 51200
        ),
        summary: SummaryTrendWidgetModel(
            monthExpenseCents: 642188,
            monthIncomeCents: 960000,
            monthBalanceCents: 317812,
            sparkline: [0.10, 0.24, 0.18, 0.40, 0.30, 0.52, 0.34],
            trend7: [0.16, 0.22, 0.18, 0.42, 0.34, 0.60, 0.38],
            monthNumber: 5,
            average7Cents: 91884
        )
    )
}

private extension WidgetSnapshot {
    var hasDisplayData: Bool {
        quickEntry.todayExpenseCents > 0
            || quickEntry.todayEntryCount > 0
            || summary.monthExpenseCents > 0
            || summary.monthIncomeCents > 0
            || summary.monthBalanceCents != 0
    }
}

#Preview("Widget Preview Light") {
    NavigationStack {
        WidgetPreviewView()
    }
    .environment(\.appEnvironment, .preview)
    .preferredColorScheme(.light)
}

#Preview("Widget Preview Dark") {
    NavigationStack {
        WidgetPreviewView()
    }
    .environment(\.appEnvironment, .preview)
    .preferredColorScheme(.dark)
}
