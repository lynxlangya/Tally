import Foundation
import CoreData

struct DefaultImportExportService: ImportExportService {
    private let billRepository: BillRepository
    private let categoryRepository: CategoryRepository
    private let recurringRepository: RecurringRepository
    private let managedObjectContext: NSManagedObjectContext?
    private let fileManager: FileManager
    private let nowProvider: () -> Date
    private let calendar: Calendar

    init(
        billRepository: BillRepository,
        categoryRepository: CategoryRepository,
        recurringRepository: RecurringRepository,
        managedObjectContext: NSManagedObjectContext? = nil,
        fileManager: FileManager = .default,
        nowProvider: @escaping () -> Date = Date.init
    ) {
        self.billRepository = billRepository
        self.categoryRepository = categoryRepository
        self.recurringRepository = recurringRepository
        self.managedObjectContext = managedObjectContext
        self.fileManager = fileManager
        self.nowProvider = nowProvider
        self.calendar = Calendar(identifier: .gregorian)
    }

    func exportCSV(request: ExportRequest) async throws -> ExportResult {
        let now = nowProvider()
        let bills = try loadBills(scope: request.scope, now: now).sorted { $0.occurredAtUTC < $1.occurredAtUTC }
        let categoryMap = try loadCategoryMap()
        let csv = buildCSV(from: bills, categoryMap: categoryMap)

        let (fromDay, toDay) = fileRangeForCSV(scope: request.scope, bills: bills, now: now)
        let fileName = "Bill_\(fromDay.replacingOccurrences(of: "-", with: ""))-\(toDay.replacingOccurrences(of: "-", with: "")).csv"
        let url = fileManager.temporaryDirectory.appendingPathComponent(fileName)

        var data = Data([0xEF, 0xBB, 0xBF])
        data.append(Data(csv.utf8))
        try data.write(to: url, options: .atomic)

        return ExportResult(
            fileURL: url,
            recordCount: bills.count,
            fileSizeBytes: Int64(data.count)
        )
    }

    func exportBackup(request: ExportRequest) async throws -> ExportResult {
        let now = nowProvider()
        let bills = try loadBills(scope: request.scope, now: now).sorted { $0.occurredAtUTC < $1.occurredAtUTC }
        let categories = try loadAllCategories().sorted {
            if $0.type == $1.type {
                return $0.sortOrder < $1.sortOrder
            }
            return $0.type.rawValue < $1.type.rawValue
        }
        let recurring = try recurringRepository.list().sorted { $0.nextFireDate < $1.nextFireDate }

        let payload = BackupPayload(
            schemaVersion: 1,
            exportedAt: now,
            appVersion: appVersionString(),
            timezone: TimeZone.autoupdatingCurrent.identifier,
            bills: bills.map(BackupBill.init),
            categories: categories.map(BackupCategory.init),
            recurringTasks: recurring.map(BackupRecurringTask.init)
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(payload)

        let fileName = "JustOne_Backup_\(Self.backupTimestampFormatter.string(from: now)).json"
        let url = fileManager.temporaryDirectory.appendingPathComponent(fileName)
        try data.write(to: url, options: .atomic)

        return ExportResult(
            fileURL: url,
            recordCount: bills.count + categories.count + recurring.count,
            fileSizeBytes: Int64(data.count)
        )
    }

    func previewImportBackup(from fileURL: URL) async throws -> ImportPreview {
        let payload = try loadBackupPayload(from: fileURL)
        let validation = try validateBackupPayload(payload)
        return ImportPreview(
            pendingCount: validation.pendingCount,
            conflictCount: validation.conflictCount,
            failedCount: validation.failedCount,
            errorSummary: validation.errorSummary
        )
    }

    func previewImportCSV(from fileURL: URL) async throws -> ImportPreview {
        let payload = try loadCSVPayload(from: fileURL)
        let validation = try validateCSVPayload(payload)
        return ImportPreview(
            pendingCount: validation.pendingCount,
            conflictCount: validation.conflictCount,
            failedCount: validation.failedCount,
            errorSummary: validation.errorSummary
        )
    }

    func importBackup(from fileURL: URL) async throws -> ImportResult {
        let payload = try loadBackupPayload(from: fileURL)
        let validation = try validateBackupPayload(payload)
        let writeResult: ImportWriteResult

        if let managedObjectContext {
            writeResult = try importValidatedBackup(validation, using: managedObjectContext)
        } else {
            writeResult = try importWithRepositories(validation)
        }

        return ImportResult(
            importedCount: writeResult.importedCount,
            skippedCount: writeResult.skippedCount + validation.conflictCount,
            failedCount: validation.failedCount
        )
    }

    func importCSV(from fileURL: URL) async throws -> ImportResult {
        let payload = try loadCSVPayload(from: fileURL)
        let validation = try validateCSVPayload(payload)

        var importedCount = 0
        var writeFailedCount = 0

        for bill in validation.bills {
            do {
                let draft = BillDraft(
                    type: bill.type,
                    amount: Money(cents: bill.amountCents),
                    occurredAtLocal: bill.occurredAtLocal,
                    note: bill.note,
                    categoryId: bill.categoryId,
                    isFromRecurring: false
                )
                _ = try billRepository.create(draft)
                importedCount += 1
            } catch {
                writeFailedCount += 1
            }
        }

        return ImportResult(
            importedCount: importedCount,
            skippedCount: validation.conflictCount,
            failedCount: validation.failedCount + writeFailedCount
        )
    }
}

private extension DefaultImportExportService {
    static let csvISO8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    static let backupTimestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter
    }()

    static let amountRegex = try? NSRegularExpression(pattern: #"^\d+(\.\d{1,2})?$"#)
    static let dayKeyRegex = try? NSRegularExpression(pattern: #"^\d{4}-\d{2}-\d{2}$"#)
    static let csvExpectedHeader = ["时间", "类型", "分类", "金额", "备注"]

    static let csvLocalDateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    static let csvISO8601FractionalFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    func loadBills(scope: ExportScope, now: Date) throws -> [BillRecord] {
        switch scope {
        case .currentMonth:
            let monthKey = String(DayKeyFormatter.dayKey(for: now).prefix(7))
            return try billRepository.list(monthKey: monthKey, type: nil)
        case .allRecords:
            return try billRepository.list()
        }
    }

    func loadAllCategories() throws -> [CategoryRecord] {
        let expense = try categoryRepository.list(type: .expense)
        let income = try categoryRepository.list(type: .income)
        return expense + income
    }

    func loadCategoryMap() throws -> [UUID: CategoryRecord] {
        let categories = try loadAllCategories()
        return Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
    }

    func buildCSV(from bills: [BillRecord], categoryMap: [UUID: CategoryRecord]) -> String {
        var lines: [String] = []
        lines.append("时间,类型,分类,金额,备注")

        for bill in bills {
            let time = Self.csvISO8601Formatter.string(from: bill.occurredAtUTC)
            let type = bill.type == .income ? "收入" : "支出"
            let category = categoryName(for: bill, categoryMap: categoryMap)
            let amount = amountText(cents: bill.amount.cents)
            let note = bill.note ?? ""

            let row = [time, type, category, amount, note]
                .map(csvEscaped)
                .joined(separator: ",")
            lines.append(row)
        }

        return lines.joined(separator: "\n")
    }

    func fileRangeForCSV(scope: ExportScope, bills: [BillRecord], now: Date) -> (from: String, to: String) {
        if !bills.isEmpty {
            let dayKeys = bills.map(\.occurredLocalDate)
            return (dayKeys.min() ?? DayKeyFormatter.dayKey(for: now), dayKeys.max() ?? DayKeyFormatter.dayKey(for: now))
        }

        switch scope {
        case .currentMonth:
            let dayKey = DayKeyFormatter.dayKey(for: now)
            let monthPrefix = String(dayKey.prefix(7))
            let from = monthPrefix + "-01"
            let to = monthPrefix + "-\(String(format: "%02d", calendar.range(of: .day, in: .month, for: now)?.count ?? 1))"
            return (from, to)
        case .allRecords:
            let dayKey = DayKeyFormatter.dayKey(for: now)
            return (dayKey, dayKey)
        }
    }

    func categoryName(for bill: BillRecord, categoryMap: [UUID: CategoryRecord]) -> String {
        let fallback = "未分类"
        guard let categoryId = bill.categoryId else { return fallback }
        return categoryMap[categoryId]?.name ?? fallback
    }

    func amountText(cents: Int) -> String {
        let decimal = Decimal(cents) / Decimal(100)
        return NSDecimalNumber(decimal: decimal).stringValue(withScale: 2)
    }

    func csvEscaped(_ value: String) -> String {
        let needsQuote = value.contains(",") || value.contains("\"") || value.contains("\n")
        guard needsQuote else { return value }
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }

    func appVersionString() -> String {
        let bundle = Bundle.main
        let shortVersion = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
        return "\(shortVersion)(\(build))"
    }

    func loadBackupPayload(from fileURL: URL) throws -> BackupPayload {
        let data = try readDataFromFileURL(fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let payload = try decoder.decode(BackupPayload.self, from: data)
            guard payload.schemaVersion == 1 else {
                throw ImportExportError.unsupportedSchema(payload.schemaVersion)
            }
            return payload
        } catch let error as ImportExportError {
            throw error
        } catch {
            throw ImportExportError.invalidBackupFile
        }
    }

    func readDataFromFileURL(_ fileURL: URL) throws -> Data {
        let didAccess = fileURL.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }
        return try Data(contentsOf: fileURL)
    }

    func loadCSVPayload(from fileURL: URL) throws -> CSVImportPayload {
        let data = try readDataFromFileURL(fileURL)
        guard var content = String(data: data, encoding: .utf8) else {
            throw ImportExportError.invalidCSVFile
        }
        if content.hasPrefix("\u{FEFF}") {
            content.removeFirst()
        }

        let parsedRows = try parseCSVRows(content)
        guard let header = parsedRows.first else {
            throw ImportExportError.invalidCSVFile
        }

        let normalizedHeader = header.columns.map(normalizedCSVHeaderCell)
        guard normalizedHeader == Self.csvExpectedHeader else {
            throw ImportExportError.invalidCSVHeader
        }

        return CSVImportPayload(
            rows: parsedRows.dropFirst().map { row in
                CSVImportRow(lineNumber: row.lineNumber, columns: row.columns)
            }
        )
    }

    func validateCSVPayload(_ payload: CSVImportPayload) throws -> CSVValidationResult {
        let categories = try loadAllCategories()
        var categoryLookup: [String: UUID] = [:]
        for category in categories {
            categoryLookup[categoryLookupKey(type: category.type, name: category.name)] = category.id
        }

        let existingBills = try billRepository.list()
        var duplicateKeys = Set(
            existingBills.map { bill in
                csvDuplicateKey(
                    amountCents: bill.amount.cents,
                    categoryId: bill.categoryId ?? SystemCategoryID.uncategorized(for: bill.type),
                    dayKey: bill.occurredLocalDate
                )
            }
        )

        var bills: [ValidatedCSVBill] = []
        var pendingCount = 0
        var conflictCount = 0
        var failedCount = 0
        var errorSummary: [String] = []

        for row in payload.rows {
            guard row.columns.count == Self.csvExpectedHeader.count else {
                markCSVFailure(
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

            guard let billType = parseCSVBillType(from: typeText) else {
                markCSVFailure(
                    lineNumber: row.lineNumber,
                    reason: "类型非法",
                    failedCount: &failedCount,
                    errorSummary: &errorSummary
                )
                continue
            }

            guard let occurredAtLocal = parseCSVDate(from: timeText) else {
                markCSVFailure(
                    lineNumber: row.lineNumber,
                    reason: "时间格式非法",
                    failedCount: &failedCount,
                    errorSummary: &errorSummary
                )
                continue
            }

            guard let amountCents = parseCents(from: amountText) else {
                markCSVFailure(
                    lineNumber: row.lineNumber,
                    reason: "金额非法",
                    failedCount: &failedCount,
                    errorSummary: &errorSummary
                )
                continue
            }

            let dayKey = DayKeyFormatter.dayKey(for: occurredAtLocal)
            let categoryId: UUID
            if categoryText.isEmpty {
                categoryId = SystemCategoryID.uncategorized(for: billType)
            } else {
                categoryId = categoryLookup[categoryLookupKey(type: billType, name: categoryText)]
                    ?? SystemCategoryID.uncategorized(for: billType)
            }

            let duplicateKey = csvDuplicateKey(
                amountCents: amountCents,
                categoryId: categoryId,
                dayKey: dayKey
            )
            if duplicateKeys.contains(duplicateKey) {
                conflictCount += 1
                continue
            }
            duplicateKeys.insert(duplicateKey)

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

    func parseCSVRows(_ content: String) throws -> [ParsedCSVRow] {
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
            throw ImportExportError.invalidCSVFile
        }

        if !row.isEmpty || !field.isEmpty {
            commitRow()
        }

        return rows
    }

    func normalizedCSVHeaderCell(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\u{FEFF}", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func parseCSVBillType(from value: String) -> BillType? {
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

    func parseCSVDate(from value: String) -> Date? {
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

    func csvDuplicateKey(amountCents: Int, categoryId: UUID, dayKey: String) -> String {
        "\(amountCents)|\(categoryId.uuidString.lowercased())|\(dayKey)"
    }

    func validateBackupPayload(_ payload: BackupPayload) throws -> BackupValidationResult {
        let existingBillsByID = Set(try billRepository.list().map(\.id))
        let existingRecurringByID = Set(try recurringRepository.list().map(\.id))
        let existingCategories = try loadAllCategories()
        let existingCategoriesByID = Dictionary(uniqueKeysWithValues: existingCategories.map { ($0.id, $0) })
        var availableCategoryIDs = Set(existingCategoriesByID.keys)

        var categories: [ValidatedCategory] = []
        var bills: [ValidatedBill] = []
        var recurring: [ValidatedRecurring] = []
        var pendingCount = 0
        var conflictCount = 0
        var failedCount = 0
        var errorCounter: [String: Int] = [:]

        for category in payload.categories {
            guard let type = BillType(rawValue: category.type) else {
                markFailure("分类类型非法", failedCount: &failedCount, errorCounter: &errorCounter)
                continue
            }

            guard !category.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                markFailure("分类名称缺失", failedCount: &failedCount, errorCounter: &errorCounter)
                continue
            }

            availableCategoryIDs.insert(category.id)

            if let existing = existingCategoriesByID[category.id], existing.isSystem {
                conflictCount += 1
                continue
            }

            pendingCount += 1
            categories.append(
                ValidatedCategory(
                    id: category.id,
                    type: type,
                    name: category.name,
                    iconKey: category.iconKey,
                    colorHex: category.colorHex,
                    sortOrder: category.sortOrder
                )
            )
        }

        for bill in payload.bills {
            guard let type = BillType(rawValue: bill.type) else {
                markFailure("账单类型非法", failedCount: &failedCount, errorCounter: &errorCounter)
                continue
            }

            guard let cents = parseCents(from: bill.amount) else {
                markFailure("金额非法", failedCount: &failedCount, errorCounter: &errorCounter)
                continue
            }

            guard isValidDayKey(bill.occurredLocalDate) else {
                markFailure("日期格式非法", failedCount: &failedCount, errorCounter: &errorCounter)
                continue
            }

            if existingBillsByID.contains(bill.id) {
                conflictCount += 1
                continue
            }

            let categoryId = resolveCategoryID(
                rawCategoryID: bill.categoryId,
                type: type,
                availableCategoryIDs: availableCategoryIDs
            )

            pendingCount += 1
            bills.append(
                ValidatedBill(
                    id: bill.id,
                    type: type,
                    amountCents: cents,
                    occurredAtUTC: bill.occurredAtUTC,
                    occurredLocalDate: bill.occurredLocalDate,
                    tzId: bill.tzId,
                    tzOffset: bill.tzOffset,
                    note: bill.note,
                    categoryId: categoryId,
                    isFromRecurring: bill.isFromRecurring,
                    createdAt: bill.createdAt,
                    updatedAt: bill.updatedAt,
                    deletedAt: bill.deletedAt,
                    trashUntil: bill.trashUntil
                )
            )
        }

        for recurringTask in payload.recurringTasks {
            guard let type = BillType(rawValue: recurringTask.type) else {
                markFailure("定时记账类型非法", failedCount: &failedCount, errorCounter: &errorCounter)
                continue
            }

            guard let cents = parseCents(from: recurringTask.amount) else {
                markFailure("定时记账金额非法", failedCount: &failedCount, errorCounter: &errorCounter)
                continue
            }

            guard RepeatRule(rawValue: recurringTask.repeatRule) != nil else {
                markFailure("重复规则非法", failedCount: &failedCount, errorCounter: &errorCounter)
                continue
            }

            guard (0...23).contains(recurringTask.hour), (0...59).contains(recurringTask.minute) else {
                markFailure("定时记账时间非法", failedCount: &failedCount, errorCounter: &errorCounter)
                continue
            }

            let categoryId = resolveCategoryID(
                rawCategoryID: recurringTask.categoryId,
                type: type,
                availableCategoryIDs: availableCategoryIDs
            )

            let isUpdate = existingRecurringByID.contains(recurringTask.id)
            pendingCount += 1

            recurring.append(
                ValidatedRecurring(
                    id: recurringTask.id,
                    type: type,
                    amountCents: cents,
                    categoryId: categoryId,
                    note: recurringTask.note,
                    firstDate: recurringTask.firstDate,
                    repeatRule: recurringTask.repeatRule,
                    nextFireDate: recurringTask.nextFireDate,
                    hour: recurringTask.hour,
                    minute: recurringTask.minute,
                    lastRunAtUTC: recurringTask.lastRunAtUTC,
                    isEnabled: recurringTask.isEnabled,
                    createdAt: recurringTask.createdAt,
                    updatedAt: recurringTask.updatedAt,
                    isUpdate: isUpdate
                )
            )
        }

        let errorSummary = errorCounter
            .sorted { lhs, rhs in
                if lhs.value == rhs.value {
                    return lhs.key < rhs.key
                }
                return lhs.value > rhs.value
            }
            .prefix(3)
            .map { "\($0.key)（\($0.value)）" }

        return BackupValidationResult(
            categories: categories,
            bills: bills,
            recurring: recurring,
            pendingCount: pendingCount,
            conflictCount: conflictCount,
            failedCount: failedCount,
            errorSummary: errorSummary
        )
    }

    func importValidatedBackup(
        _ validation: BackupValidationResult,
        using parentContext: NSManagedObjectContext
    ) throws -> ImportWriteResult {
        let childContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        childContext.parent = parentContext
        childContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        return try childContext.performAndWaitThrowing {
            do {
                var importedCount = 0
                var skippedCount = 0

                var categoryObjects = try fetchManagedObjectMap(entityName: "Category", context: childContext)
                for category in validation.categories {
                    if let object = categoryObjects[category.id] {
                        let isSystem = object.value(forKey: "isSystem") as? Bool ?? false
                        if isSystem {
                            skippedCount += 1
                            continue
                        }
                        apply(category: category, to: object)
                        importedCount += 1
                    } else {
                        let object = NSEntityDescription.insertNewObject(forEntityName: "Category", into: childContext)
                        apply(category: category, to: object)
                        categoryObjects[category.id] = object
                        importedCount += 1
                    }
                }

                let categoryIDs = Set(categoryObjects.keys)

                let billObjects = try fetchManagedObjectMap(entityName: "Bill", context: childContext)
                for bill in validation.bills {
                    if billObjects[bill.id] != nil {
                        skippedCount += 1
                        continue
                    }
                    let object = NSEntityDescription.insertNewObject(forEntityName: "Bill", into: childContext)
                    let resolvedCategoryID = categoryIDs.contains(bill.categoryId)
                        ? bill.categoryId
                        : SystemCategoryID.uncategorized(for: bill.type)
                    apply(bill: bill, resolvedCategoryID: resolvedCategoryID, to: object)
                    importedCount += 1
                }

                var recurringObjects = try fetchManagedObjectMap(entityName: "RecurringTask", context: childContext)
                for recurring in validation.recurring {
                    if let object = recurringObjects[recurring.id] {
                        apply(recurring: recurring, to: object)
                        importedCount += 1
                    } else {
                        let object = NSEntityDescription.insertNewObject(forEntityName: "RecurringTask", into: childContext)
                        apply(recurring: recurring, to: object)
                        recurringObjects[recurring.id] = object
                        importedCount += 1
                    }
                }

                if childContext.hasChanges {
                    try childContext.save()
                }

                try parentContext.performAndWaitThrowing {
                    if parentContext.hasChanges {
                        try parentContext.save()
                    }
                }

                return ImportWriteResult(importedCount: importedCount, skippedCount: skippedCount)
            } catch {
                childContext.rollback()
                throw ImportExportError.importFailed(reason: error.localizedDescription)
            }
        }
    }

    func importWithRepositories(_ validation: BackupValidationResult) throws -> ImportWriteResult {
        var importedCount = 0
        var skippedCount = 0

        let existingCategories = try loadAllCategories()
        var categoriesByID = Dictionary(uniqueKeysWithValues: existingCategories.map { ($0.id, $0) })

        for category in validation.categories {
            if let existing = categoriesByID[category.id] {
                if existing.isSystem {
                    skippedCount += 1
                    continue
                }
                let updated = CategoryRecord(
                    id: existing.id,
                    type: category.type,
                    name: category.name,
                    iconKey: category.iconKey,
                    colorHex: category.colorHex,
                    isSystem: false,
                    sortOrder: category.sortOrder
                )
                try categoryRepository.update(updated)
                categoriesByID[existing.id] = updated
                importedCount += 1
            } else {
                let record = CategoryRecord(
                    id: category.id,
                    type: category.type,
                    name: category.name,
                    iconKey: category.iconKey,
                    colorHex: category.colorHex,
                    isSystem: false,
                    sortOrder: category.sortOrder
                )
                try categoryRepository.create(record)
                categoriesByID[record.id] = record
                importedCount += 1
            }
        }

        let existingBillIDs = Set(try billRepository.list().map(\.id))
        for bill in validation.bills {
            if existingBillIDs.contains(bill.id) {
                skippedCount += 1
                continue
            }
            let draft = BillDraft(
                type: bill.type,
                amount: Money(cents: bill.amountCents),
                occurredAtLocal: bill.occurredAtUTC,
                note: bill.note,
                categoryId: bill.categoryId,
                isFromRecurring: bill.isFromRecurring
            )
            _ = try billRepository.create(draft)
            importedCount += 1
        }

        let existingRecurring = try recurringRepository.list()
        let recurringByID = Dictionary(uniqueKeysWithValues: existingRecurring.map { ($0.id, $0) })

        for recurring in validation.recurring {
            let record = RecurringTaskRecord(
                id: recurring.id,
                type: recurring.type,
                amount: Money(cents: recurring.amountCents),
                categoryId: recurring.categoryId,
                note: recurring.note,
                firstDate: recurring.firstDate,
                repeatRule: recurring.repeatRule,
                nextFireDate: recurring.nextFireDate,
                hour: recurring.hour,
                minute: recurring.minute,
                lastRunAtUTC: recurring.lastRunAtUTC,
                isEnabled: recurring.isEnabled,
                createdAt: recurring.createdAt,
                updatedAt: recurring.updatedAt
            )

            if recurringByID[record.id] != nil {
                try recurringRepository.update(record)
            } else {
                try recurringRepository.create(record)
            }
            importedCount += 1
        }

        return ImportWriteResult(importedCount: importedCount, skippedCount: skippedCount)
    }

    func fetchManagedObjectMap(entityName: String, context: NSManagedObjectContext) throws -> [UUID: NSManagedObject] {
        let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
        let objects = try context.fetch(request)
        var result: [UUID: NSManagedObject] = [:]
        for object in objects {
            if let id = object.value(forKey: "id") as? UUID {
                result[id] = object
            }
        }
        return result
    }

    func apply(category: ValidatedCategory, to object: NSManagedObject) {
        object.setValue(category.id, forKey: "id")
        object.setValue(category.type.rawValue, forKey: "type")
        object.setValue(category.name, forKey: "name")
        object.setValue(category.iconKey, forKey: "iconKey")
        object.setValue(category.colorHex.map { Int64($0) }, forKey: "colorHex")
        object.setValue(false, forKey: "isSystem")
        object.setValue(Int64(category.sortOrder), forKey: "sortOrder")
    }

    func apply(bill: ValidatedBill, resolvedCategoryID: UUID, to object: NSManagedObject) {
        object.setValue(bill.id, forKey: "id")
        object.setValue(bill.type.rawValue, forKey: "type")
        object.setValue(Int64(bill.amountCents), forKey: "amount")
        object.setValue(bill.occurredAtUTC, forKey: "occurredAtUTC")
        object.setValue(bill.tzId, forKey: "tzId")
        object.setValue(Int32(bill.tzOffset), forKey: "tzOffset")
        object.setValue(bill.occurredLocalDate, forKey: "occurredLocalDate")
        object.setValue(bill.note, forKey: "note")
        object.setValue(resolvedCategoryID, forKey: "categoryId")
        object.setValue(bill.isFromRecurring, forKey: "isFromRecurring")
        object.setValue(bill.createdAt, forKey: "createdAt")
        object.setValue(bill.updatedAt, forKey: "updatedAt")
        object.setValue(bill.deletedAt, forKey: "deletedAt")
        object.setValue(bill.trashUntil, forKey: "trashUntil")
    }

    func apply(recurring: ValidatedRecurring, to object: NSManagedObject) {
        object.setValue(recurring.id, forKey: "id")
        object.setValue(recurring.type.rawValue, forKey: "type")
        object.setValue(Int64(recurring.amountCents), forKey: "amount")
        object.setValue(recurring.categoryId, forKey: "categoryId")
        object.setValue(recurring.note, forKey: "note")
        object.setValue(recurring.firstDate, forKey: "firstDate")
        object.setValue(recurring.repeatRule, forKey: "repeatRule")
        object.setValue(recurring.nextFireDate, forKey: "nextFireDate")
        object.setValue(Int16(recurring.hour), forKey: "hour")
        object.setValue(Int16(recurring.minute), forKey: "minute")
        object.setValue(recurring.lastRunAtUTC, forKey: "lastRunAtUTC")
        object.setValue(recurring.isEnabled, forKey: "isEnabled")
        object.setValue(recurring.createdAt, forKey: "createdAt")
        object.setValue(recurring.updatedAt, forKey: "updatedAt")
    }

    func resolveCategoryID(rawCategoryID: UUID?, type: BillType, availableCategoryIDs: Set<UUID>) -> UUID {
        guard let rawCategoryID else {
            return SystemCategoryID.uncategorized(for: type)
        }
        if availableCategoryIDs.contains(rawCategoryID) {
            return rawCategoryID
        }
        return SystemCategoryID.uncategorized(for: type)
    }

    func parseCents(from text: String) -> Int? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let regex = Self.amountRegex {
            let range = NSRange(location: 0, length: trimmed.utf16.count)
            guard regex.firstMatch(in: trimmed, options: [], range: range) != nil else {
                return nil
            }
        }

        guard let decimal = Decimal(string: trimmed, locale: Locale(identifier: "en_US_POSIX")), decimal > 0 else {
            return nil
        }

        let centsDecimal = decimal * 100
        let centsNumber = NSDecimalNumber(decimal: centsDecimal)
        let rounded = centsNumber.rounding(accordingToBehavior: NSDecimalNumberHandler(
            roundingMode: .plain,
            scale: 0,
            raiseOnExactness: false,
            raiseOnOverflow: false,
            raiseOnUnderflow: false,
            raiseOnDivideByZero: false
        ))
        let cents = rounded.intValue
        return cents > 0 ? cents : nil
    }

    func isValidDayKey(_ dayKey: String) -> Bool {
        if let regex = Self.dayKeyRegex {
            let range = NSRange(location: 0, length: dayKey.utf16.count)
            guard regex.firstMatch(in: dayKey, options: [], range: range) != nil else {
                return false
            }
        }
        return DayKeyFormatter.date(from: dayKey) != nil
    }

    func markFailure(_ reason: String, failedCount: inout Int, errorCounter: inout [String: Int]) {
        failedCount += 1
        errorCounter[reason, default: 0] += 1
    }

    func markCSVFailure(
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

private extension NSDecimalNumber {
    func stringValue(withScale scale: Int16) -> String {
        let behavior = NSDecimalNumberHandler(
            roundingMode: .plain,
            scale: scale,
            raiseOnExactness: false,
            raiseOnOverflow: false,
            raiseOnUnderflow: false,
            raiseOnDivideByZero: false
        )
        let rounded = self.rounding(accordingToBehavior: behavior)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = Int(scale)
        formatter.maximumFractionDigits = Int(scale)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: rounded) ?? rounded.stringValue
    }
}

private struct BackupPayload: Codable {
    let schemaVersion: Int
    let exportedAt: Date
    let appVersion: String
    let timezone: String
    let bills: [BackupBill]
    let categories: [BackupCategory]
    let recurringTasks: [BackupRecurringTask]
}

private struct BackupBill: Codable {
    let id: UUID
    let type: String
    let amount: String
    let occurredAtUTC: Date
    let occurredLocalDate: String
    let tzId: String
    let tzOffset: Int
    let note: String?
    let categoryId: UUID?
    let isFromRecurring: Bool
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    let trashUntil: Date?

    init(_ source: BillRecord) {
        id = source.id
        type = source.type.rawValue
        amount = NSDecimalNumber(decimal: source.amount.decimalAmount).stringValue(withScale: 2)
        occurredAtUTC = source.occurredAtUTC
        occurredLocalDate = source.occurredLocalDate
        tzId = source.tzId
        tzOffset = source.tzOffset
        note = source.note
        categoryId = source.categoryId
        isFromRecurring = source.isFromRecurring
        createdAt = source.createdAt
        updatedAt = source.updatedAt
        deletedAt = source.deletedAt
        trashUntil = source.trashUntil
    }
}

private struct BackupCategory: Codable {
    let id: UUID
    let type: String
    let name: String
    let iconKey: String
    let colorHex: Int?
    let isSystem: Bool
    let sortOrder: Int

    init(_ source: CategoryRecord) {
        id = source.id
        type = source.type.rawValue
        name = source.name
        iconKey = source.iconKey
        colorHex = source.colorHex
        isSystem = source.isSystem
        sortOrder = source.sortOrder
    }
}

private struct BackupRecurringTask: Codable {
    let id: UUID
    let type: String
    let amount: String
    let categoryId: UUID?
    let note: String?
    let firstDate: Date
    let repeatRule: String
    let nextFireDate: Date
    let hour: Int
    let minute: Int
    let lastRunAtUTC: Date?
    let isEnabled: Bool
    let createdAt: Date
    let updatedAt: Date

    init(_ source: RecurringTaskRecord) {
        id = source.id
        type = source.type.rawValue
        amount = NSDecimalNumber(decimal: source.amount.decimalAmount).stringValue(withScale: 2)
        categoryId = source.categoryId
        note = source.note
        firstDate = source.firstDate
        repeatRule = source.repeatRule
        nextFireDate = source.nextFireDate
        hour = source.hour
        minute = source.minute
        lastRunAtUTC = source.lastRunAtUTC
        isEnabled = source.isEnabled
        createdAt = source.createdAt
        updatedAt = source.updatedAt
    }
}

private struct BackupValidationResult {
    let categories: [ValidatedCategory]
    let bills: [ValidatedBill]
    let recurring: [ValidatedRecurring]
    let pendingCount: Int
    let conflictCount: Int
    let failedCount: Int
    let errorSummary: [String]
}

private struct CSVImportPayload {
    let rows: [CSVImportRow]
}

private struct CSVImportRow {
    let lineNumber: Int
    let columns: [String]
}

private struct ParsedCSVRow {
    let lineNumber: Int
    let columns: [String]
}

private struct CSVValidationResult {
    let bills: [ValidatedCSVBill]
    let pendingCount: Int
    let conflictCount: Int
    let failedCount: Int
    let errorSummary: [String]
}

private struct ImportWriteResult {
    let importedCount: Int
    let skippedCount: Int
}

private struct ValidatedCategory {
    let id: UUID
    let type: BillType
    let name: String
    let iconKey: String
    let colorHex: Int?
    let sortOrder: Int
}

private struct ValidatedBill {
    let id: UUID
    let type: BillType
    let amountCents: Int
    let occurredAtUTC: Date
    let occurredLocalDate: String
    let tzId: String
    let tzOffset: Int
    let note: String?
    let categoryId: UUID
    let isFromRecurring: Bool
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    let trashUntil: Date?
}

private struct ValidatedRecurring {
    let id: UUID
    let type: BillType
    let amountCents: Int
    let categoryId: UUID
    let note: String?
    let firstDate: Date
    let repeatRule: String
    let nextFireDate: Date
    let hour: Int
    let minute: Int
    let lastRunAtUTC: Date?
    let isEnabled: Bool
    let createdAt: Date
    let updatedAt: Date
    let isUpdate: Bool
}

private struct ValidatedCSVBill {
    let type: BillType
    let amountCents: Int
    let occurredAtLocal: Date
    let note: String?
    let categoryId: UUID
}

private enum ImportExportError: LocalizedError {
    case invalidBackupFile
    case invalidCSVFile
    case invalidCSVHeader
    case unsupportedSchema(Int)
    case importFailed(reason: String)

    var errorDescription: String? {
        switch self {
        case .invalidBackupFile:
            return "备份文件格式不正确"
        case .invalidCSVFile:
            return "CSV 文件格式不正确"
        case .invalidCSVHeader:
            return "CSV 列头不匹配，请使用“时间、类型、分类、金额、备注”模板"
        case .unsupportedSchema(let version):
            return "备份版本不兼容（schemaVersion: \(version)）"
        case .importFailed(let reason):
            return "导入失败：\(reason)"
        }
    }
}
