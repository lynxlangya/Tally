import Combine
import Foundation

enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case zhHans

    var id: String { rawValue }

    var title: String {
        "简体中文"
    }

    var nativeName: String {
        "简体中文"
    }

    var subtitle: String {
        "中国大陆"
    }

    var shortCode: String {
        "简"
    }

    var sampleTitle: String {
        "今天"
    }

    var sampleSubtitle: String {
        "本月支出"
    }

    var localeIdentifier: String {
        "zh-Hans-CN"
    }

    var locale: Locale {
        Locale(identifier: localeIdentifier)
    }
}

final class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    static let defaultLanguage: AppLanguage = .zhHans

    @Published private(set) var selectedLanguage: AppLanguage
    let languageOptions = AppLanguage.allCases

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let storedValue = defaults.string(forKey: Keys.selectedLanguage)
        selectedLanguage = AppLanguage(rawValue: storedValue ?? "") ?? Self.defaultLanguage

        if storedValue != selectedLanguage.rawValue {
            persist()
        }
    }

    var currentLocale: Locale {
        selectedLanguage.locale
    }

    func setLanguage(_ language: AppLanguage) {
        guard language != selectedLanguage else { return }
        selectedLanguage = language
        persist()
    }

    func resetToDefault() {
        setLanguage(Self.defaultLanguage)
    }

    private func persist() {
        defaults.set(selectedLanguage.rawValue, forKey: Keys.selectedLanguage)
    }
}

private enum Keys {
    static let selectedLanguage = "language.selected"
}
