import SwiftUI
import Combine

enum AppearanceMode: String, CaseIterable {
    case light
    case dark
    case system
}

struct AccentOption: Identifiable, Equatable {
    let id: String
    let color: Color
    let name: String?
}

struct ThemeSettings {
    var appearance: AppearanceMode
    var accent: AccentOption
}

final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published private(set) var settings: ThemeSettings
    let accentOptions: [AccentOption]

    private init() {
        let options: [AccentOption] = [
            AccentOption(id: "green", color: LegacyColors.accent, name: "Green"),
            AccentOption(id: "orange", color: Color(hex: 0xF59E0B), name: "Orange"),
            AccentOption(id: "blue", color: Color(hex: 0x3B82F6), name: "Blue"),
            AccentOption(id: "purple", color: Color(hex: 0xA855F7), name: "Purple"),
            AccentOption(id: "pink", color: Color(hex: 0xEC4899), name: "Pink"),
            AccentOption(id: "yellow", color: Color(hex: 0xFACC15), name: "Yellow"),
            AccentOption(id: "cyan", color: Color(hex: 0x22D3EE), name: "Cyan"),
            AccentOption(id: "red", color: Color(hex: 0xEF4444), name: "Red")
        ]
        self.accentOptions = options
        self.settings = ThemeSettings(appearance: .dark, accent: options.first!)
    }

    func setAppearance(_ mode: AppearanceMode) {
        // no-op for MVP
    }

    func setAccent(_ accent: AccentOption) {
        // no-op for MVP
    }
}
