import XCTest

final class TallyHomeDeletionUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testDeletesHomeBillFromContextMenu() throws {
        let app = XCUIApplication()
        app.launchWithPreviewData()

        let billRow = app.billRow(containing: ["示例账单", "支出"])
        XCTAssertTrue(billRow.waitForExistence(timeout: 5))

        billRow.press(forDuration: 1.0)

        let deleteMenuItem = app.buttons["删除"].firstMatch
        XCTAssertTrue(deleteMenuItem.waitForExistence(timeout: 3))
        deleteMenuItem.tap()

        let confirmDeleteButton = app.buttons["确定删除"].firstMatch
        XCTAssertTrue(confirmDeleteButton.waitForExistence(timeout: 3))
        confirmDeleteButton.tap()

        XCTAssertFalse(billRow.waitForExistence(timeout: 2))
    }

    func testCreatesExpenseFromQuickEntryFAB() throws {
        let app = XCUIApplication()
        app.launchWithPreviewData()

        let quickEntryButton = app.buttons["shell.quickEntry"].firstMatch
        XCTAssertTrue(quickEntryButton.waitForExistence(timeout: 5))
        quickEntryButton.tap()

        let oneKey = app.buttons["quickEntry.key.1"].firstMatch
        XCTAssertTrue(oneKey.waitForExistence(timeout: 3))
        oneKey.tap()
        app.buttons["quickEntry.key.2"].firstMatch.tap()

        let saveButton = app.buttons["quickEntry.save"].firstMatch
        XCTAssertTrue(saveButton.waitForExistence(timeout: 3))
        XCTAssertTrue(saveButton.isEnabled)
        saveButton.tap()

        let createdBillRow = app.billRow(containing: ["支出", "¥12.00"])
        XCTAssertTrue(createdBillRow.waitForExistence(timeout: 5))
    }
}

private extension XCUIApplication {
    func launchWithPreviewData() {
        launchArguments = ["-tallyUsePreviewData"]
        launch()
    }

    func billRow(containing fragments: [String]) -> XCUIElement {
        let format = fragments
            .map { _ in "label CONTAINS %@" }
            .joined(separator: " AND ")
        let predicate = NSPredicate(format: format, argumentArray: fragments)
        return otherElements.matching(predicate).firstMatch
    }
}
