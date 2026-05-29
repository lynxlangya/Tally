import XCTest
@testable import Tally

final class LanguageManagerTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "LanguageManagerTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testDefaultLanguageIsSystem() {
        let manager = LanguageManager(defaults: defaults, systemLocaleProvider: { Locale(identifier: "en-US") })

        XCTAssertEqual(manager.selectedLanguage, .system)
        XCTAssertTrue(manager.currentLocale.identifier.lowercased().hasPrefix("en"))
        XCTAssertEqual(manager.effectiveLanguage, .en)
    }

    func testLanguageOptionsExposeSystemSimplifiedChineseAndEnglish() {
        let manager = LanguageManager(defaults: defaults)

        XCTAssertEqual(manager.languageOptions, [.system, .zhHans, .en])
    }

    func testLanguageSelectionPersistsAcrossManagers() {
        var manager = LanguageManager(defaults: defaults)

        manager.setLanguage(.en)
        manager = LanguageManager(defaults: defaults)

        XCTAssertEqual(manager.selectedLanguage, .en)
        XCTAssertTrue(manager.currentLocale.identifier.lowercased().hasPrefix("en"))
        XCTAssertEqual(defaults.string(forKey: "language.selected"), "en")
    }

    func testResetRestoresDefaultLanguage() {
        let manager = LanguageManager(defaults: defaults)

        manager.resetToDefault()

        XCTAssertEqual(manager.selectedLanguage, .system)
    }

    func testLegacyStoredLanguageFallsBackToSystemLanguage() {
        defaults.set("english", forKey: "language.selected")

        let manager = LanguageManager(defaults: defaults, systemLocaleProvider: { Locale(identifier: "zh-Hans-CN") })

        XCTAssertEqual(manager.selectedLanguage, .system)
        XCTAssertTrue(manager.currentLocale.identifier.lowercased().hasPrefix("zh"))
        XCTAssertEqual(manager.effectiveLanguage, .zhHans)
        XCTAssertEqual(defaults.string(forKey: "language.selected"), "system")
    }

    func testSystemLanguageResolvesEnglishAndChineseLocales() {
        XCTAssertEqual(AppLanguage.supportedContentLanguage(for: Locale(identifier: "en_US")), .en)
        XCTAssertEqual(AppLanguage.supportedContentLanguage(for: Locale(identifier: "zh_Hans_CN")), .zhHans)
        XCTAssertEqual(AppLanguage.supportedContentLanguage(for: Locale(identifier: "ja_JP")), .zhHans)
    }

    func testSystemLocaleFallsBackToSupportedLocaleForUnsupportedLanguages() {
        let manager = LanguageManager(defaults: defaults, systemLocaleProvider: { Locale(identifier: "ja-JP") })

        XCTAssertEqual(manager.selectedLanguage, .system)
        XCTAssertEqual(manager.effectiveLanguage, .zhHans)
        XCTAssertEqual(manager.currentLocale.identifier, "zh-Hans-CN")
    }

    func testLocalizedResourcesDatesAndMoneyDifferBetweenChineseAndEnglish() {
        let zhLocale = Locale(identifier: "zh-Hans-CN")
        let enLocale = Locale(identifier: "en-US")
        let date = fixedDate(year: 2026, month: 5, day: 1)

        XCTAssertEqual(TallyLocalization.text(.home, locale: zhLocale), "首页")
        XCTAssertEqual(TallyLocalization.text(.home, locale: enLocale), "Home")
        XCTAssertEqual(TallyLocalization.monthDayTitle(for: date, locale: zhLocale), "5月1日")
        XCTAssertEqual(TallyLocalization.monthDayTitle(for: date, locale: enLocale), "May 1")
        XCTAssertEqual(MoneyFormatter.string(fromCents: 642_188, locale: zhLocale), "¥6,421.88")
        XCTAssertEqual(MoneyFormatter.string(fromCents: 642_188, locale: enLocale), "CN¥6,421.88")
    }

    private func fixedDate(year: Int, month: Int, day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai") ?? .current
        let components = DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: 9,
            minute: 0,
            second: 0
        )
        return calendar.date(from: components) ?? Date(timeIntervalSince1970: 0)
    }
}
