import PhotosUI
import SwiftUI
import UIKit

struct AccountSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tabBarVisibility) private var tabBarVisibility
    @AppStorage(ProfileIdentityStore.nameKey) private var profileName: String = ProfileIdentityStore.defaultName
    @AppStorage(ProfileIdentityStore.avatarDataKey) private var avatarData: Data = Data()
    @ObservedObject private var languageManager = LanguageManager.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var avatarItem: PhotosPickerItem?
    @State private var avatarErrorMessage: String?
    @FocusState private var isNameFocused: Bool

    private var accent: Color {
        themeManager.settings.accent.color
    }

    private var hasCustomAvatar: Bool {
        !avatarData.isEmpty
    }

    var body: some View {
        ZStack {
            Color.tallyBg.ignoresSafeArea()

            VStack(spacing: 0) {
                TallyNavHeader(
                    title: TallyLocalization.text(.accountSettings, locale: languageManager.currentLocale),
                    onBack: close
                )

                ScrollView {
                    VStack(spacing: TallySpacing.s6) {
                        avatarSection
                        nameSection

                        if let avatarErrorMessage {
                            Text(avatarErrorMessage)
                                .font(TallyType.body(12, weight: .medium))
                                .foregroundStyle(Color.red.opacity(0.84))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.horizontal, TallySpacing.s4)
                    .padding(.top, TallySpacing.s2)
                    .padding(.bottom, 120)
                }
                .scrollIndicators(.hidden)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            tabBarVisibility?.setVisible(false)
            profileName = ProfileIdentityStore.limitedInput(profileName)
        }
        .onDisappear {
            normalizeProfileName()
        }
        .onChange(of: avatarItem) { _, newValue in
            guard let newValue else { return }
            Task { await loadAvatar(from: newValue) }
        }
    }

    private var avatarSection: some View {
        VStack(spacing: TallySpacing.s5) {
            ProfileAvatarView(
                avatarData: avatarData,
                size: 112,
                cornerRadius: 30,
                appIcon: themeManager.settings.appIcon,
                accent: accent,
                showsEditBadge: true
            )
            .shadow(color: Color.tallyInk.opacity(0.12), radius: 18, x: 0, y: 10)

            HStack(spacing: TallySpacing.s3) {
                PhotosPicker(selection: $avatarItem, matching: .images) {
                    actionPill(
                        title: TallyLocalization.text("change_avatar", locale: languageManager.currentLocale),
                        systemImage: "photo"
                    )
                }
                .buttonStyle(.plain)

                if hasCustomAvatar {
                    Button {
                        avatarData = Data()
                        avatarItem = nil
                        avatarErrorMessage = nil
                    } label: {
                        actionPill(
                            title: TallyLocalization.text("use_default_avatar", locale: languageManager.currentLocale),
                            systemImage: "app"
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, TallySpacing.s5)
        .padding(.vertical, TallySpacing.s6)
        .background(Color.tallySurface)
        .clipShape(RoundedRectangle(cornerRadius: TallyRadii.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: TallyRadii.xl, style: .continuous)
                .stroke(Color.tallyLine, lineWidth: 0.5)
        )
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: TallySpacing.s3) {
            HStack {
                Eyebrow(TallyLocalization.text("name", locale: languageManager.currentLocale))

                Spacer()

                Text("\(profileName.count)/\(ProfileIdentityStore.nameLimit)")
                    .font(TallyType.num(11, weight: .medium))
                    .foregroundStyle(Color.tallyInkFaint)
            }

            HStack(spacing: TallySpacing.s2) {
                TextField(
                    TallyLocalization.text("enter_name", locale: languageManager.currentLocale),
                    text: nameBinding
                )
                .font(TallyType.display(22, weight: .semibold))
                .foregroundStyle(Color.tallyInk)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .submitLabel(.done)
                .focused($isNameFocused)
                .onSubmit {
                    normalizeProfileName()
                    isNameFocused = false
                }

                if !profileName.isEmpty {
                    Button {
                        profileName = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color.tallyInkFaint)
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(TallyLocalization.text(.delete, locale: languageManager.currentLocale))
                }
            }
            .padding(.horizontal, TallySpacing.s4)
            .frame(height: 58)
            .background(Color.tallySurface2)
            .clipShape(RoundedRectangle(cornerRadius: TallyRadii.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: TallyRadii.md, style: .continuous)
                    .stroke(isNameFocused ? accent : Color.tallyLine, lineWidth: isNameFocused ? 1.2 : 0.5)
            )
        }
        .padding(TallySpacing.s5)
        .background(Color.tallySurface)
        .clipShape(RoundedRectangle(cornerRadius: TallyRadii.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: TallyRadii.xl, style: .continuous)
                .stroke(Color.tallyLine, lineWidth: 0.5)
        )
    }

    private var nameBinding: Binding<String> {
        Binding(
            get: { profileName },
            set: { profileName = ProfileIdentityStore.limitedInput($0) }
        )
    }

    private func actionPill(title: String, systemImage: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold))
            Text(title)
                .font(TallyType.body(13, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .foregroundStyle(Color.tallyInk)
        .padding(.horizontal, 14)
        .frame(height: 38)
        .background(Color.tallySurface2)
        .clipShape(Capsule(style: .continuous))
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.tallyLine, lineWidth: 0.5)
        )
    }

    @MainActor
    private func loadAvatar(from item: PhotosPickerItem) async {
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data),
                  let compressed = image.profileAvatarJPEGData(maxDimension: 512) else {
                avatarErrorMessage = TallyLocalization.text("avatar_update_failed", locale: languageManager.currentLocale)
                avatarItem = nil
                return
            }

            avatarData = compressed
            avatarErrorMessage = nil
            avatarItem = nil
        } catch {
            avatarErrorMessage = TallyLocalization.text("avatar_update_failed", locale: languageManager.currentLocale)
            avatarItem = nil
        }
    }

    private func normalizeProfileName() {
        profileName = ProfileIdentityStore.persistedName(for: profileName)
    }

    private func close() {
        normalizeProfileName()
        dismiss()
    }
}

private extension UIImage {
    func profileAvatarJPEGData(maxDimension: CGFloat) -> Data? {
        let longestSide = max(size.width, size.height)
        guard longestSide > 0 else { return nil }

        let scale = min(1, maxDimension / longestSide)
        let outputSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(size: outputSize, format: format)
        let resized = renderer.image { _ in
            UIColor.systemBackground.setFill()
            UIBezierPath(rect: CGRect(origin: .zero, size: outputSize)).fill()
            draw(in: CGRect(origin: .zero, size: outputSize))
        }
        return resized.jpegData(compressionQuality: 0.82)
    }
}

#Preview {
    NavigationStack {
        AccountSettingsView()
    }
    .environment(\.appEnvironment, .preview)
}
