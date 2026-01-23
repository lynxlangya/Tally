import SwiftUI
import PhotosUI

struct AccountSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tabBarVisibility) private var tabBarVisibility
    @AppStorage("profileName") private var profileName: String = "Alex Doe"
    @AppStorage("profileAvatarData") private var avatarData: Data = Data()
    @State private var avatarItem: PhotosPickerItem?

    var body: some View {
        VStack(spacing: JOSpacing.lg) {
            header

            VStack(spacing: JOSpacing.xl) {
                avatarSection
                nameSection
            }
            .padding(.top, JOSpacing.lg)

            Spacer()
        }
        .padding(.horizontal, JOSpacing.lg)
        .padding(.top, JOSpacing.lg)
        .background(JOColors.background.ignoresSafeArea())
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
        JOHeaderBar(
            title: "账号设置",
            titleFont: JOTypography.headline,
            titleColor: JOColors.profileRowTitle
        ) {
            dismiss()
        }
    }

    private var avatarSection: some View {
        VStack(spacing: JOSpacing.md) {
            ZStack {
                Circle()
                    .fill(JOColors.surface)
                    .frame(width: 96, height: 96)
                    .overlay(Circle().stroke(JOColors.cardBorder, lineWidth: 1))

                if let image = avatarImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 88, height: 88)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(JOColors.profileRowSubtitle)
                }
            }

            PhotosPicker(selection: $avatarItem, matching: .images) {
                Text("更换头像")
                    .font(JOTypography.caption)
                    .foregroundStyle(JOColors.accent)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: JOSpacing.sm) {
            Text("名称")
                .font(JOTypography.caption)
                .foregroundStyle(JOColors.textSecondary)

            JOLimitedTextField(
                text: $profileName,
                placeholder: "输入名称",
                maxLength: 12,
                font: UIFont.systemFont(ofSize: 17, weight: .medium),
                textColor: UIColor(JOColors.textPrimary),
                placeholderColor: UIColor(JOColors.textSecondary),
                returnKeyType: .done
            )
            .padding(.horizontal, JOSpacing.lg)
            .frame(height: 48)
            .background(JOColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(JOColors.cardBorder, lineWidth: 1)
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
