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

    func testDefaultLanguageFollowsSystem() {
        let manager = LanguageManager(defaults: defaults)

        XCTAssertEqual(manager.selectedLanguage, .system)
        XCTAssertNil(manager.selectedLanguage.localeIdentifier)
    }

    func testLanguageSelectionPersistsAcrossManagers() {
        var manager = LanguageManager(defaults: defaults)

        manager.setLanguage(.english)
        manager = LanguageManager(defaults: defaults)

        XCTAssertEqual(manager.selectedLanguage, .english)
        XCTAssertEqual(manager.selectedLanguage.localeIdentifier, "en-US")
    }

    func testResetRestoresSystemLanguage() {
        let manager = LanguageManager(defaults: defaults)

        manager.setLanguage(.japanese)
        manager.resetToSystem()

        XCTAssertEqual(manager.selectedLanguage, .system)
    }

    func testInvalidStoredLanguageFallsBackToSystem() {
        defaults.set("esperanto", forKey: "language.selected")

        let manager = LanguageManager(defaults: defaults)

        XCTAssertEqual(manager.selectedLanguage, .system)
    }
}
