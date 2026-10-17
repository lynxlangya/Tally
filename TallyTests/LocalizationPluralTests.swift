import XCTest
@testable import Tally

final class LocalizationPluralTests: XCTestCase {
    private let enLocale = Locale(identifier: "en-US")
    private let zhLocale = Locale(identifier: "zh-Hans-CN")

    func testEnglishSingleCountStringsUseSingularOnlyForOne() {
        let cases: [(L10nKey, one: String, other: String)] = [
            (.billCount, "1 entry", "%d entries"),
            (.entryCount, "1 entry", "%d entries"),
            (.billRecordedDays, "1 day tracked", "%d days tracked"),
            (.categoryCountSummary, "1 category · View all", "%d categories · View all"),
            (.transactionCount, "1 record", "%d records")
        ]

        for (key, one, other) in cases {
            XCTAssertEqual(TallyLocalization.format(key, locale: enLocale, 1), one, key.rawValue)
            for count in [0, 2, 12] {
                XCTAssertEqual(
                    TallyLocalization.format(key, locale: enLocale, count),
                    String(format: other, count),
                    "\(key.rawValue) count=\(count)"
                )
            }
        }

        XCTAssertEqual(
            TallyLocalization.format("category_limit_message", locale: enLocale, 1),
            "You can add up to 1 category"
        )
        XCTAssertEqual(
            TallyLocalization.format("category_limit_message", locale: enLocale, 50),
            "You can add up to 50 categories"
        )
    }

    func testEnglishMultiArgumentStringsPluralizeOnlyTheCountedNoun() {
        XCTAssertEqual(TallyLocalization.format("export_generated", locale: enLocale, "CSV", 1), "Generated CSV (1 record)")
        XCTAssertEqual(TallyLocalization.format("export_generated", locale: enLocale, "CSV", 3), "Generated CSV (3 records)")
        XCTAssertEqual(
            TallyLocalization.format("export_generated_with_size", locale: enLocale, "JSON", 1, "2 KB"),
            "Generated JSON (1 record, 2 KB)"
        )
        XCTAssertEqual(
            TallyLocalization.format("export_generated_with_size", locale: enLocale, "JSON", 0, "2 KB"),
            "Generated JSON (0 records, 2 KB)"
        )
        XCTAssertEqual(
            TallyLocalization.format("import_export_log_meta", locale: enLocale, "May 1", "10:00", 1, 1),
            "May 1 · 10:00 · 1 record · 1 error"
        )
        XCTAssertEqual(
            TallyLocalization.format("import_export_log_meta", locale: enLocale, "May 1", "10:00", 1, 2),
            "May 1 · 10:00 · 1 record · 2 errors"
        )
        XCTAssertEqual(
            TallyLocalization.format("import_export_log_meta", locale: enLocale, "May 1", "10:00", 5, 0),
            "May 1 · 10:00 · 5 records · 0 errors"
        )
        XCTAssertEqual(
            TallyLocalization.format("import_export_range_subtitle", locale: enLocale, "May 1", "May 1", 1),
            "Range May 1 - May 1 · 1 day"
        )
        XCTAssertEqual(
            TallyLocalization.format("import_export_range_subtitle", locale: enLocale, "May 1", "May 7", 7),
            "Range May 1 - May 7 · 7 days"
        )
        XCTAssertEqual(TallyLocalization.format("records_unit", locale: enLocale, 1), "record")
        XCTAssertEqual(TallyLocalization.format("records_unit", locale: enLocale, 0), "records")
        XCTAssertEqual(TallyLocalization.format("records_unit", locale: enLocale, 8), "records")
    }

    func testChineseCountStringsStayUnchanged() {
        for count in [1, 2] {
            XCTAssertEqual(TallyLocalization.format(.billCount, locale: zhLocale, count), "\(count) 笔")
            XCTAssertEqual(TallyLocalization.format(.entryCount, locale: zhLocale, count), "\(count) 笔")
            XCTAssertEqual(TallyLocalization.format(.billRecordedDays, locale: zhLocale, count), "已记 \(count) 天")
            XCTAssertEqual(TallyLocalization.format(.categoryCountSummary, locale: zhLocale, count), "共 \(count) 项 · 看全部")
            XCTAssertEqual(TallyLocalization.format(.transactionCount, locale: zhLocale, count), "\(count) 笔记录")
            XCTAssertEqual(TallyLocalization.format("category_limit_message", locale: zhLocale, count), "最多新增 \(count) 个分类")
            XCTAssertEqual(TallyLocalization.format("export_generated", locale: zhLocale, "CSV", count), "已生成CSV（\(count)条）")
            XCTAssertEqual(
                TallyLocalization.format("export_generated_with_size", locale: zhLocale, "JSON", count, "2 KB"),
                "已生成JSON（\(count)条，2 KB）"
            )
            XCTAssertEqual(
                TallyLocalization.format("import_export_log_meta", locale: zhLocale, "5月1日", "10:00", count, count),
                "5月1日 · 10:00 · \(count) 条 · \(count) 错误"
            )
            XCTAssertEqual(
                TallyLocalization.format("import_export_range_subtitle", locale: zhLocale, "5月1日", "5月7日", count),
                "跨度 5月1日 - 5月7日 · \(count) 天"
            )
            XCTAssertEqual(TallyLocalization.format("records_unit", locale: zhLocale, count), "条记录")
        }
    }
}
