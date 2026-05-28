import XCTest
@testable import Tally

final class FeatureErrorMessageTests: XCTestCase {
    func testRepositoryInvalidDataUsesFriendlyMessageWithoutFieldName() {
        let message = FeatureErrorMessage.message(
            for: RepositoryError.invalidData(field: "Bill.amount"),
            fallback: "保存失败"
        )

        XCTAssertEqual(message, "本地数据异常，请稍后重试")
        XCTAssertFalse(message.contains("Bill.amount"))
        XCTAssertFalse(message.contains("RepositoryError"))
    }

    func testRepositoryNotFoundUsesFriendlyMessage() {
        let message = FeatureErrorMessage.message(
            for: RepositoryError.notFound,
            fallback: "保存失败"
        )

        XCTAssertEqual(message, "未找到对应数据，请返回后重试")
    }

    func testLocalizedErrorDescriptionCanPassThrough() {
        let message = FeatureErrorMessage.message(
            for: MockUserFacingError(),
            fallback: "保存失败"
        )

        XCTAssertEqual(message, "请检查文件后重试")
    }

    func testUnknownErrorUsesContextFallback() {
        let message = FeatureErrorMessage.message(
            for: NSError(domain: "test", code: 1),
            fallback: "保存失败"
        )

        XCTAssertEqual(message, "保存失败")
    }
}

private struct MockUserFacingError: LocalizedError {
    var errorDescription: String? { "请检查文件后重试" }
}
