import SwiftUI
import PhotosUI

struct AccountSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tabBarVisibility) private var tabBarVisibility
    @AppStorage("profileName") private var profileName: String = "Alex Doe"
    @AppStorage("profileAvatarData") private var avatarData: Data = Data()
    @State private var avatarItem: PhotosPickerItem?

    var body: some View {
        VStack(spacing: LegacySpacing.lg) {
            header

            VStack(spacing: LegacySpacing.xl) {
                avatarSection
                nameSection
            }
            .padding(.top, LegacySpacing.lg)

            Spacer()
        }
        .padding(.horizontal, LegacySpacing.lg)
        .padding(.top, LegacySpacing.lg)
        .background(LegacyColors.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            tabBarVisibility?.setVisible(false)
        }
        .onChange(of: avatarItem) { _, newValue in
            guard let item = newValue else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data),
                   let compressed = image.jpegData(compressionQuality: 0.8) {
                    avatarData = compressed
                }
            }
        }
    }

    private var header: some View {
        LegacyHeaderBar(
            title: TallyLocalization.text(.accountSettings, locale: LanguageManager.shared.currentLocale),
            titleFont: LegacyTypography.headline,
            titleColor: LegacyColors.profileRowTitle
        ) {
            dismiss()
        }
    }

    private var avatarSection: some View {
        VStack(spacing: LegacySpacing.md) {
            ZStack {
                Circle()
                    .fill(LegacyColors.surface)
                    .frame(width: 96, height: 96)
                    .overlay(Circle().stroke(LegacyColors.cardBorder, lineWidth: 1))

                if let image = avatarImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 88, height: 88)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(LegacyColors.profileRowSubtitle)
                }
            }

            PhotosPicker(selection: $avatarItem, matching: .images) {
                Text(TallyLocalization.text("change_avatar", locale: LanguageManager.shared.currentLocale))
                    .font(LegacyTypography.caption)
                    .foregroundStyle(LegacyColors.accent)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: LegacySpacing.sm) {
            Text(TallyLocalization.text("name", locale: LanguageManager.shared.currentLocale))
                .font(LegacyTypography.caption)
                .foregroundStyle(LegacyColors.textSecondary)

            LegacyLimitedTextField(
                text: $profileName,
                placeholder: TallyLocalization.text("enter_name", locale: LanguageManager.shared.currentLocale),
                maxLength: 12,
                font: UIFont.systemFont(ofSize: 17, weight: .medium),
                textColor: UIColor(LegacyColors.textPrimary),
                placeholderColor: UIColor(LegacyColors.textSecondary),
                returnKeyType: .done
            )
            .padding(.horizontal, LegacySpacing.lg)
            .frame(height: 48)
            .background(LegacyColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(LegacyColors.cardBorder, lineWidth: 1)
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var avatarImage: UIImage? {
        guard !avatarData.isEmpty else { return nil }
        return UIImage(data: avatarData)
    }
}

#Preview {
    NavigationStack {
        AccountSettingsView()
    }
    .environment(\.appEnvironment, .preview)
}
