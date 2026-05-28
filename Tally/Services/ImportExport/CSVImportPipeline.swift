import Foundation

struct CSVImportPayload {
    let rows: [CSVImportRow]
}

struct CSVImportRow {
    let lineNumber: Int
    let columns: [String]
}

struct CSVValidationResult {
    let bills: [ValidatedCSVBill]
    let pendingCount: Int
    let conflictCount: Int
    let failedCount: Int
    let errorSummary: [String]
}

struct ValidatedCSVBill {
    let type: BillType
    let amountCents: Int
    let occurredAtLocal: Date
    let note: String?
    let categoryId: UUID
}

enum CSVImportPipelineError: LocalizedError {
    case invalidFile
    case invalidHeader

    var errorDescription: String? {
        switch self {
        case .invalidFile:
            return "CSV 文件格式不正确"
        case .invalidHeader:
            return "CSV 列头不匹配，请使用“时间、类型、分类、金额、备注”模板"
        }
    }
}

struct CSVImportPipeline {
    static let expectedHeader = ["时间", "类型", "分类", "金额", "备注"]

    private static let csvISO8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static let csvISO8601FractionalFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let csvLocalDateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    func loadPayload(from data: Data) throws -> CSVImportPayload {
        guard var content = String(data: data, encoding: .utf8) else {
            throw CSVImportPipelineError.invalidFile
        }
        if content.hasPrefix("\u{FEFF}") {
            content.removeFirst()
        }

        let parsedRows = try parseRows(content)
        guard let header = parsedRows.first else {
            throw CSVImportPipelineError.invalidFile
        }

        let normalizedHeader = header.columns.map(normalizeHeaderCell)
        guard normalizedHeader == Self.expectedHeader else {
            throw CSVImportPipelineError.invalidHeader
        }

        return CSVImportPayload(
            rows: parsedRows.dropFirst().map { parsed in
                CSVImportRow(lineNumber: parsed.lineNumber, columns: parsed.columns)
            }
        )
    }

    func validate(
        payload: CSVImportPayload,
        categories: [CategoryRecord],
        existingBills: [BillRecord],
        parseAmount: (String) -> Int?
    ) -> CSVValidationResult {
        var categoryLookup: [String: UUID] = [:]
        for category in categories {
            categoryLookup[categoryLookupKey(type: category.type, name: category.name)] = category.id
        }

        var duplicateKeys = Set(
            existingBills.map { bill in
                duplicateKey(
                    amountCents: bill.amount.cents,
                    categoryId: bill.categoryId ?? SystemCategoryID.uncategorized(for: bill.type),
                    occurredAt: bill.occurredAtUTC
                )
            }
        )

        var bills: [ValidatedCSVBill] = []
        var pendingCount = 0
        var conflictCount = 0
        var failedCount = 0
        var errorSummary: [String] = []

        for row in payload.rows {
            guard row.columns.count == Self.expectedHeader.count else {
                markFailure(
                    lineNumber: row.lineNumber,
                    reason: "列数不匹配",
                    failedCount: &failedCount,
                    errorSummary: &errorSummary
                )
                continue
            }

            let timeText = row.columns[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let typeText = row.columns[1].trimmingCharacters(in: .whitespacesAndNewlines)
            let categoryText = row.columns[2].trimmingCharacters(in: .whitespacesAndNewlines)
            let amountText = row.columns[3].trimmingCharacters(in: .whitespacesAndNewlines)
            let noteText = row.columns[4].trimmingCharacters(in: .whitespacesAndNewlines)

            guard let billType = parseBillType(from: typeText) else {
                markFailure(
                    lineNumber: row.lineNumber,
                    reason: "类型非法",
                    failedCount: &failedCount,
                    errorSummary: &errorSummary
                )
                continue
            }

            guard let occurredAtLocal = parseDate(from: timeText) else {
                markFailure(
                    lineNumber: row.lineNumber,
                    reason: "时间格式非法",
                    failedCount: &failedCount,
                    errorSummary: &errorSummary
                )
                continue
            }

            guard let amountCents = parseAmount(amountText) else {
                markFailure(
                    lineNumber: row.lineNumber,
                    reason: "金额非法",
                    failedCount: &failedCount,
                    errorSummary: &errorSummary
                )
                continue
            }

            let categoryId: UUID
            if categoryText.isEmpty {
                categoryId = SystemCategoryID.uncategorized(for: billType)
            } else {
                categoryId = categoryLookup[categoryLookupKey(type: billType, name: categoryText)]
                    ?? SystemCategoryID.uncategorized(for: billType)
            }

            let key = duplicateKey(amountCents: amountCents, categoryId: categoryId, occurredAt: occurredAtLocal)
            if duplicateKeys.contains(key) {
                conflictCount += 1
                continue
            }

            duplicateKeys.insert(key)
            pendingCount += 1
            bills.append(
                ValidatedCSVBill(
                    type: billType,
                    amountCents: amountCents,
                    occurredAtLocal: occurredAtLocal,
                    note: noteText.isEmpty ? nil : noteText,
                    categoryId: categoryId
                )
            )
        }

        return CSVValidationResult(
            bills: bills,
            pendingCount: pendingCount,
            conflictCount: conflictCount,
            failedCount: failedCount,
            errorSummary: errorSummary
        )
    }
}

private extension CSVImportPipeline {
    struct ParsedCSVRow {
        let lineNumber: Int
        let columns: [String]
    }

    func parseRows(_ content: String) throws -> [ParsedCSVRow] {
        var rows: [ParsedCSVRow] = []
        var row: [String] = []
        var field = ""
        var inQuotes = false
        var currentLine = 1
        var rowStartLine = 1
        var index = content.startIndex

        func commitRow() {
            row.append(field)
            let isBlank = row.allSatisfy { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            if !isBlank {
                rows.append(ParsedCSVRow(lineNumber: rowStartLine, columns: row))
            }
            row.removeAll(keepingCapacity: true)
            field.removeAll(keepingCapacity: true)
        }

        while index < content.endIndex {
            let character = content[index]

            if inQuotes {
                if character == "\"" {
                    let nextIndex = content.index(after: index)
                    if nextIndex < content.endIndex, content[nextIndex] == "\"" {
                        field.append("\"")
                        index = nextIndex
                    } else {
                        inQuotes = false
                    }
                } else {
                    field.append(character)
                }
            } else {
                switch character {
                case "\"":
                    inQuotes = true
                case ",":
                    row.append(field)
                    field.removeAll(keepingCapacity: true)
                case "\n":
                    commitRow()
                    currentLine += 1
                    rowStartLine = currentLine
                case "\r":
                    commitRow()
                    let nextIndex = content.index(after: index)
                    if nextIndex < content.endIndex, content[nextIndex] == "\n" {
                        index = nextIndex
                    }
                    currentLine += 1
                    rowStartLine = currentLine
                default:
                    field.append(character)
                }
            }

            index = content.index(after: index)
        }

        if inQuotes {
            throw CSVImportPipelineError.invalidFile
        }

        if !row.isEmpty || !field.isEmpty {
            commitRow()
        }

        return rows
    }

    func normalizeHeaderCell(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\u{FEFF}", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func parseBillType(from value: String) -> BillType? {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch normalized {
        case "收入", "income":
            return .income
        case "支出", "expense":
            return .expense
        default:
            return nil
        }
    }

    func parseDate(from value: String) -> Date? {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return nil }
        if let date = Self.csvISO8601Formatter.date(from: normalized) {
            return date
        }
        if let date = Self.csvISO8601FractionalFormatter.date(from: normalized) {
            return date
        }
        return Self.csvLocalDateTimeFormatter.date(from: normalized)
    }

    func categoryLookupKey(type: BillType, name: String) -> String {
        "\(type.rawValue)|\(name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())"
    }

    func duplicateKey(amountCents: Int, categoryId: UUID, occurredAt: Date) -> String {
        let timestampSeconds = Int64(occurredAt.timeIntervalSince1970)
        return "\(amountCents)|\(categoryId.uuidString.lowercased())|\(timestampSeconds)"
    }

    func markFailure(
        lineNumber: Int,
        reason: String,
        failedCount: inout Int,
        errorSummary: inout [String]
    ) {
        failedCount += 1
        if errorSummary.count < 3 {
            errorSummary.append("第\(lineNumber)行：\(reason)")
        }
    }
}
