import Foundation

/// 导入导出统一数据口径（MVP 基线）：
/// - 金额：CNY，固定两位小数；导入时禁止负数记录。
/// - 时间：使用 occurredAtUTC + occurredLocalDate，避免跨时区分组漂移。
enum ExportScope: String, CaseIterable, Identifiable, Sendable {
    case currentMonth
    case allRecords

    var id: String { rawValue }

    var title: String {
        switch self {
        case .currentMonth:
            return "当前月"
        case .allRecords:
            return "全部"
        }
    }
}

enum ExportType: Sendable {
    case csv
    case backupJSON
}

struct ExportRequest: Sendable {
    let scope: ExportScope
    let type: ExportType
}

struct ExportResult: Sendable {
    let fileURL: URL
    let recordCount: Int
    let fileSizeBytes: Int64?
}

struct ImportPreview: Sendable {
    let pendingCount: Int
    let conflictCount: Int
    let failedCount: Int
    let errorSummary: [String]
}

struct ImportResult: Sendable {
    let importedCount: Int
    let skippedCount: Int
    let failedCount: Int
}
