import XCTest
@testable import Tally

final class ThemeManagerTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "ThemeManagerTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testDefaultSettingsUseFactoryTheme() {
        let manager = ThemeManager(defaults: defaults)

        XCTAssertEqual(manager.settings.appearance, .dark)
        XCTAssertEqual(manager.settings.accent.id, "vermilion")
        XCTAssertEqual(manager.settings.appIcon, .vermilion)
        XCTAssertFalse(manager.settings.reduceMotion)
        XCTAssertTrue(manager.settings.hapticFeedback)
    }

    func testSelectionsPersistAcrossManagers() {
        var manager = ThemeManager(defaults: defaults)
        let brass = manager.accentOptions.first { $0.id == "brass" }!

        manager.setAppearance(.light)
        manager.setAccent(brass)
        manager.setAppIcon(.inkNote)
        manager.setReduceMotion(true)
        manager.setHapticFeedback(false)

        manager = ThemeManager(defaults: defaults)

        XCTAssertEqual(manager.settings.appearance, .light)
        XCTAssertEqual(manager.settings.accent.id, "brass")
        XCTAssertEqual(manager.settings.appIcon, .inkNote)
        XCTAssertTrue(manager.settings.reduceMotion)
        XCTAssertFalse(manager.settings.hapticFeedback)
    }

    func testResetRestoresFactoryTheme() {
        let manager = ThemeManager(defaults: defaults)
        let brass = manager.accentOptions.first { $0.id == "brass" }!

        manager.setAppearance(.light)
        manager.setAccent(brass)
        manager.setReduceMotion(true)
        manager.resetToDefaults()

        XCTAssertEqual(manager.settings.appearance, .dark)
        XCTAssertEqual(manager.settings.accent.id, "vermilion")
        XCTAssertFalse(manager.settings.reduceMotion)
        XCTAssertTrue(manager.settings.hapticFeedback)
    }

    func testAppIconAlternateNamesMatchInfoPlistKeys() {
        XCTAssertNil(ThemeAppIconOption.vermilion.alternateIconName)
        XCTAssertEqual(ThemeAppIconOption.moon.alternateIconName, "AppIconMoon")
        XCTAssertEqual(ThemeAppIconOption.ink.alternateIconName, "AppIconInk")
        XCTAssertEqual(ThemeAppIconOption.inkNote.alternateIconName, "AppIconInkNote")
    }

}
