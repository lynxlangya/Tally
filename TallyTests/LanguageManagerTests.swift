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

    func testDefaultLanguageIsSimplifiedChinese() {
        let manager = LanguageManager(defaults: defaults)

        XCTAssertEqual(manager.selectedLanguage, .zhHans)
        XCTAssertEqual(manager.selectedLanguage.localeIdentifier, "zh-Hans-CN")
    }

    func testLanguageOptionsOnlyExposeSimplifiedChinese() {
        let manager = LanguageManager(defaults: defaults)

        XCTAssertEqual(manager.languageOptions, [.zhHans])
    }

    func testLanguageSelectionPersistsAcrossManagers() {
        var manager = LanguageManager(defaults: defaults)

        manager.setLanguage(.zhHans)
        manager = LanguageManager(defaults: defaults)

        XCTAssertEqual(manager.selectedLanguage, .zhHans)
        XCTAssertEqual(defaults.string(forKey: "language.selected"), "zhHans")
    }

    func testResetRestoresDefaultLanguage() {
        let manager = LanguageManager(defaults: defaults)

        manager.resetToDefault()

        XCTAssertEqual(manager.selectedLanguage, .zhHans)
    }

    func testLegacyStoredLanguageFallsBackToSimplifiedChinese() {
        defaults.set("english", forKey: "language.selected")

        let manager = LanguageManager(defaults: defaults)

        XCTAssertEqual(manager.selectedLanguage, .zhHans)
        XCTAssertEqual(defaults.string(forKey: "language.selected"), "zhHans")
    }
}
