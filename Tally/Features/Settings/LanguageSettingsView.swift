import SwiftUI
import UIKit

struct LanguageSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tabBarVisibility) private var tabBarVisibility
    @ObservedObject private var languageManager = LanguageManager.shared
    @ObservedObject private var themeManager = ThemeManager.shared

    private var selectedLanguage: AppLanguage {
        languageManager.selectedLanguage
    }

    private var accent: Color {
        themeManager.settings.accent.color
    }

    var body: some View {
        ZStack {
            Color.tallyBg.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, TallySpacing.s6)
                    .padding(.top, TallySpacing.s4)
                    .padding(.bottom, TallySpacing.s6)

                ScrollView {
                    VStack(spacing: TallySpacing.s7) {
                        previewCard
                        languageSection
                        formatPreviewSection
                    }
                    .padding(.horizontal, TallySpacing.s6)
                    .padding(.bottom, TallySpacing.s9)
                }
                .scrollIndicators(.hidden)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .environment(\.locale, languageManager.currentLocale)
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
            .accessibilityLabel(Text(TallyLocalization.text(.cancel, locale: languageManager.currentLocale)))

            Spacer()

            Text(TallyLocalization.text(.language, locale: languageManager.currentLocale))
                .font(TallyType.display(18, weight: .semibold))
                .foregroundStyle(Color.tallyInk)

            Spacer()

            Color.clear
                .frame(width: 36, height: 36)
        }
    }

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: TallySpacing.s2) {
                    Text(TallyLocalization.text(.language, locale: languageManager.currentLocale).uppercased())
                        .font(TallyType.body(11, weight: .semibold))
                        .tracking(1.8)
                        .foregroundStyle(Color.tallyInkFaint)

                    Text(selectedLanguage.nativeName)
                        .font(TallyType.display(30, weight: .semibold))
                        .foregroundStyle(Color.tallyInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }

                Spacer(minLength: TallySpacing.s3)

                LanguageCodeTile(
                    code: selectedLanguage.shortCode,
                    accent: accent
                )
            }
            .padding(.horizontal, TallySpacing.s5)
            .padding(.top, TallySpacing.s5)

            HStack(alignment: .bottom, spacing: TallySpacing.s4) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(selectedLanguage.sampleTitle(locale: languageManager.currentLocale))
                        .font(TallyType.body(14, weight: .semibold))
                        .foregroundStyle(Color.tallyInk)
                    Text(selectedLanguage.sampleSubtitle(locale: languageManager.currentLocale))
                        .font(TallyType.body(12, weight: .medium))
                        .foregroundStyle(Color.tallyInkFaint)
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 4) {
                    Text(formattedMonth)
                        .font(TallyType.body(11, weight: .medium))
                        .foregroundStyle(Color.tallyInkFaint)
                    Text(formattedAmount)
                        .font(TallyType.num(20, weight: .semibold))
                        .foregroundStyle(Color.tallyInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)
                }
            }
            .padding(.horizontal, TallySpacing.s5)
            .padding(.top, TallySpacing.s7)
            .padding(.bottom, TallySpacing.s5)
        }
        .background(Color.tallySurface)
        .clipShape(RoundedRectangle(cornerRadius: TallyRadii.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: TallyRadii.xl, style: .continuous)
                .stroke(Color.tallyLine, lineWidth: 0.5)
        )
        .tallyShadow(.shadow2)
    }

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: TallySpacing.s4) {
            LanguageSectionTitle(title: TallyLocalization.text(.applicationLanguage, locale: languageManager.currentLocale), trailing: selectedLanguage.nativeName)

            VStack(spacing: 0) {
                ForEach(Array(languageManager.languageOptions.enumerated()), id: \.element.id) { index, language in
                    LanguageOptionRow(
                        language: language,
                        locale: languageManager.currentLocale,
                        isSelected: selectedLanguage == language,
                        accent: accent
                    ) {
                        select(language)
                    }

                    if index < languageManager.languageOptions.count - 1 {
                        LanguageDividerLine()
                            .padding(.leading, 72)
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

    private var formatPreviewSection: some View {
        VStack(alignment: .leading, spacing: TallySpacing.s4) {
            LanguageSectionTitle(title: TallyLocalization.text(.formatPreview, locale: languageManager.currentLocale), trailing: selectedLanguage.localeIdentifier)

            VStack(spacing: 0) {
                LanguageFormatRow(title: TallyLocalization.text(.date, locale: languageManager.currentLocale), value: formattedDate)
                LanguageDividerLine()
                    .padding(.leading, TallySpacing.s4)
                LanguageFormatRow(title: TallyLocalization.text(.month, locale: languageManager.currentLocale), value: formattedMonth)
                LanguageDividerLine()
                    .padding(.leading, TallySpacing.s4)
                LanguageFormatRow(title: TallyLocalization.text(.amount, locale: languageManager.currentLocale), value: formattedAmount)
            }
            .background(Color.tallySurface)
            .clipShape(RoundedRectangle(cornerRadius: TallyRadii.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: TallyRadii.lg, style: .continuous)
                    .stroke(Color.tallyLine, lineWidth: 0.5)
            )
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = languageManager.currentLocale
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: previewDate)
    }

    private var formattedMonth: String {
        let formatter = DateFormatter()
        formatter.locale = languageManager.currentLocale
        formatter.setLocalizedDateFormatFromTemplate("yMMM")
        return formatter.string(from: previewDate)
    }

    private var formattedAmount: String {
        MoneyFormatter.string(fromCents: 642_188, locale: languageManager.currentLocale)
    }

    private var previewDate: Date {
        Date(timeIntervalSinceReferenceDate: 800_000_000)
    }

    private func select(_ language: AppLanguage) {
        if themeManager.settings.hapticFeedback {
            UISelectionFeedbackGenerator().selectionChanged()
        }

        if themeManager.settings.reduceMotion {
            languageManager.setLanguage(language)
        } else {
            withAnimation(.tallyBase) {
                languageManager.setLanguage(language)
            }
        }
    }
}

private struct LanguageSectionTitle: View {
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
                    .minimumScaleFactor(0.72)
            }
        }
        .padding(.horizontal, TallySpacing.s1)
    }
}

private struct LanguageOptionRow: View {
    let language: AppLanguage
    let locale: Locale
    let isSelected: Bool
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: TallySpacing.s4) {
                LanguageCodeTile(
                    code: language.shortCode,
                    accent: accent,
                    isCompact: true
                )

                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(language.displayTitle(locale: locale))
                            .font(TallyType.body(15, weight: .semibold))
                            .foregroundStyle(Color.tallyInk)
                            .lineLimit(1)

                        if language.displayTitle(locale: locale) != language.nativeName {
                            Text(language.nativeName)
                                .font(TallyType.body(11, weight: .medium))
                                .foregroundStyle(Color.tallyInkFaint)
                                .lineLimit(1)
                        }
                    }

                    Text(language.displaySubtitle(locale: locale))
                        .font(TallyType.body(12, weight: .medium))
                        .foregroundStyle(Color.tallyInkFaint)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                LanguageRadio(isSelected: isSelected, accent: accent)
            }
            .padding(.horizontal, TallySpacing.s4)
            .frame(height: 68)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(language.displayTitle(locale: locale))，\(language.displaySubtitle(locale: locale))")
        .languageSelectedAccessibility(isSelected)
    }
}

private struct LanguageCodeTile: View {
    let code: String
    let accent: Color
    var isCompact = false

    var body: some View {
        RoundedRectangle(cornerRadius: isCompact ? TallyRadii.sm : TallyRadii.lg, style: .continuous)
            .fill(accent.opacity(0.16))
            .frame(width: isCompact ? 42 : 64, height: isCompact ? 42 : 64)
            .overlay(
                RoundedRectangle(cornerRadius: isCompact ? TallyRadii.sm : TallyRadii.lg, style: .continuous)
                    .stroke(accent.opacity(0.42), lineWidth: 0.75)
            )
            .overlay {
                Text(code)
                    .font(TallyType.body(isCompact ? 15 : 22, weight: .semibold))
                    .foregroundStyle(accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)
            }
    }
}

private struct LanguageRadio: View {
    let isSelected: Bool
    let accent: Color

    var body: some View {
        Circle()
            .strokeBorder(isSelected ? accent : Color.tallyLineHi, lineWidth: isSelected ? 6 : 1.4)
            .frame(width: 22, height: 22)
            .background(
                Circle()
                    .fill(Color.tallySurface)
            )
    }
}

private struct LanguageFormatRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: TallySpacing.s4) {
            Text(title)
                .font(TallyType.body(14, weight: .semibold))
                .foregroundStyle(Color.tallyInk)

            Spacer(minLength: TallySpacing.s3)

            Text(value)
                .font(TallyType.body(13, weight: .medium))
                .foregroundStyle(Color.tallyInkDim)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(.horizontal, TallySpacing.s4)
        .frame(height: 52)
    }
}

private struct LanguageDividerLine: View {
    var body: some View {
        Rectangle()
            .fill(Color.tallyLine)
            .frame(height: 0.5)
    }
}

private extension View {
    @ViewBuilder
    func languageSelectedAccessibility(_ isSelected: Bool) -> some View {
        if isSelected {
            accessibilityAddTraits(.isSelected)
        } else {
            self
        }
    }
}

#Preview("Language Settings Light") {
    NavigationStack {
        LanguageSettingsView()
    }
    .environment(\.appEnvironment, .preview)
    .preferredColorScheme(.light)
}

#Preview("Language Settings Dark") {
    NavigationStack {
        LanguageSettingsView()
    }
    .environment(\.appEnvironment, .preview)
    .preferredColorScheme(.dark)
}
