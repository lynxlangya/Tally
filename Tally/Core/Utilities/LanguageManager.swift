import Combine
import Foundation

enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case system
    case zhHans
    case english
    case japanese
    case korean

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system:
            return "跟随系统"
        case .zhHans:
            return "简体中文"
        case .english:
            return "English"
        case .japanese:
            return "日本語"
        case .korean:
            return "한국어"
        }
    }

    var nativeName: String {
        switch self {
        case .system:
            return Locale.autoupdatingCurrent.localizedString(forIdentifier: Locale.autoupdatingCurrent.identifier) ?? "System"
        case .zhHans:
            return "简体中文"
        case .english:
            return "English"
        case .japanese:
            return "日本語"
        case .korean:
            return "한국어"
        }
    }

    var subtitle: String {
        switch self {
        case .system:
            return "使用 iOS 当前语言"
        case .zhHans:
            return "中国大陆"
        case .english:
            return "United States"
        case .japanese:
            return "日本"
        case .korean:
            return "대한민국"
        }
    }

    var shortCode: String {
        switch self {
        case .system:
            return "AUTO"
        case .zhHans:
            return "简"
        case .english:
            return "EN"
        case .japanese:
            return "日"
        case .korean:
            return "한"
        }
    }

    var sampleTitle: String {
        switch self {
        case .system:
            return "System"
        case .zhHans:
            return "今天"
        case .english:
            return "Today"
        case .japanese:
            return "今日"
        case .korean:
            return "오늘"
        }
    }

    var sampleSubtitle: String {
        switch self {
        case .system:
            return "Auto"
        case .zhHans:
            return "本月支出"
        case .english:
            return "Monthly expense"
        case .japanese:
            return "今月の支出"
        case .korean:
            return "이번 달 지출"
        }
    }

    var localeIdentifier: String? {
        switch self {
        case .system:
            return nil
        case .zhHans:
            return "zh-Hans-CN"
        case .english:
            return "en-US"
        case .japanese:
            return "ja-JP"
        case .korean:
            return "ko-KR"
        }
    }

    var locale: Locale {
        guard let localeIdentifier else { return .autoupdatingCurrent }
        return Locale(identifier: localeIdentifier)
    }
}

final class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    static let defaultLanguage: AppLanguage = .system

    @Published private(set) var selectedLanguage: AppLanguage
    let languageOptions = AppLanguage.allCases

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        selectedLanguage = AppLanguage(rawValue: defaults.string(forKey: Keys.selectedLanguage) ?? "")
            ?? Self.defaultLanguage
    }

    var currentLocale: Locale {
        selectedLanguage.locale
    }

    func setLanguage(_ language: AppLanguage) {
        guard language != selectedLanguage else { return }
        selectedLanguage = language
        persist()
    }

    func resetToSystem() {
        setLanguage(Self.defaultLanguage)
    }

    private func persist() {
        defaults.set(selectedLanguage.rawValue, forKey: Keys.selectedLanguage)
    }
}

private enum Keys {
    static let selectedLanguage = "language.selected"
}
