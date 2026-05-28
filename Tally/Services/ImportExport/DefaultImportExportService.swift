import Foundation

struct DefaultImportExportService: ImportExportService {
    private let billRepository: BillRepository
    private let categoryRepository: CategoryRepository
    private let recurringRepository: RecurringRepository
    private let importWriteRepository: ImportWriteRepository?
    private let csvImportPipeline: CSVImportPipeline
    private let fileManager: FileManager
    private let nowProvider: () -> Date
    private let calendar: Calendar

    init(
        billRepository: BillRepository,
        categoryRepository: CategoryRepository,
        recurringRepository: RecurringRepository,
        importWriteRepository: ImportWriteRepository? = nil,
        csvImportPipeline: CSVImportPipeline = CSVImportPipeline(),
        fileManager: FileManager = .default,
        nowProvider: @escaping () -> Date = Date.init
    ) {
        self.billRepository = billRepository
        self.categoryRepository = categoryRepository
        self.recurringRepository = recurringRepository
        self.importWriteRepository = importWriteRepository
        self.csvImportPipeline = csvImportPipeline
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

        let fileName = "Tally_Backup_\(Self.backupTimestampFormatter.string(from: now)).json"
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
        guard let importWriteRepository else {
            throw ImportExportError.importEnvironmentUnavailable
        }
        let writeResult: ImportWriteResult
        do {
            writeResult = try await importWriteRepository.importBackup(
                categories: validation.categories,
                bills: validation.bills,
                recurringTasks: validation.recurringTasks
            )
        } catch {
            throw ImportExportError.importFailed(reason: error.localizedDescription)
        }
        let result = ImportResult(
            importedCount: writeResult.importedCount,
            skippedCount: writeResult.skippedCount + validation.conflictCount,
            failedCount: validation.failedCount
        )
        refreshWidgetSnapshot()
        return result
    }

    func importCSV(from fileURL: URL) async throws -> ImportResult {
        let payload = try loadCSVPayload(from: fileURL)
        let validation = try validateCSVPayload(payload)

        if let importWriteRepository {
            let now = nowProvider()
            let bills = validation.bills.map { bill in
                let snapshot = TimePolicy.snapshot(for: bill.occurredAtLocal)
                return BackupImportBill(
                    id: UUID(),
                    type: bill.type,
                    amountCents: bill.amountCents,
                    occurredAtUTC: snapshot.occurredAtUTC,
                    occurredLocalDate: snapshot.occurredLocalDate,
                    tzId: snapshot.tzId,
                    tzOffset: snapshot.tzOffset,
                    note: bill.note,
                    categoryId: bill.categoryId,
                    isFromRecurring: false,
                    createdAt: now,
                    updatedAt: now,
                    deletedAt: nil,
                    trashUntil: nil
                )
            }
            do {
                let writeResult = try await importWriteRepository.importBills(bills)
                let result = ImportResult(
                    importedCount: writeResult.importedCount,
                    skippedCount: writeResult.skippedCount + validation.conflictCount,
                    failedCount: validation.failedCount
                )
                refreshWidgetSnapshot()
                return result
            } catch {
                let result = ImportResult(
                    importedCount: 0,
                    skippedCount: validation.conflictCount,
                    failedCount: validation.failedCount + validation.bills.count
                )
                refreshWidgetSnapshot()
                return result
            }
        }

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

        let result = ImportResult(
            importedCount: importedCount,
            skippedCount: validation.conflictCount,
            failedCount: validation.failedCount + writeFailedCount
        )
        refreshWidgetSnapshot()
        return result
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

    func refreshWidgetSnapshot() {
        WidgetSnapshotService.refresh(using: billRepository, now: nowProvider())
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
        return try csvImportPipeline.loadPayload(from: data)
    }

    func validateCSVPayload(_ payload: CSVImportPayload) throws -> CSVValidationResult {
        let categories = try loadAllCategories()
        let existingBills = try billRepository.list()
        return csvImportPipeline.validate(
            payload: payload,
            categories: categories,
            existingBills: existingBills,
            parseAmount: { parseCents(from: $0) }
        )
    }

    func validateBackupPayload(_ payload: BackupPayload) throws -> BackupValidationResult {
        let existingBillsByID = Set(try billRepository.list().map(\.id))
        let existingCategories = try loadAllCategories()
        let existingCategoriesByID = Dictionary(uniqueKeysWithValues: existingCategories.map { ($0.id, $0) })
        var availableCategoryIDs = Set(existingCategoriesByID.keys)
        var seenCategoryIDs = Set<UUID>()
        var seenBillIDs = Set<UUID>()
        var seenRecurringIDs = Set<UUID>()

        var categories: [BackupImportCategory] = []
        var bills: [BackupImportBill] = []
        var recurringTasks: [BackupImportRecurringTask] = []
        var pendingCount = 0
        var conflictCount = 0
        var failedCount = 0
        var errorCounter: [String: Int] = [:]

        for category in payload.categories {
            if !seenCategoryIDs.insert(category.id).inserted {
                conflictCount += 1
                continue
            }

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
                BackupImportCategory(
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
            if !seenBillIDs.insert(bill.id).inserted {
                conflictCount += 1
                continue
            }

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
                BackupImportBill(
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
            if !seenRecurringIDs.insert(recurringTask.id).inserted {
                conflictCount += 1
                continue
            }

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

            pendingCount += 1

            recurringTasks.append(
                BackupImportRecurringTask(
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
                    updatedAt: recurringTask.updatedAt
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
            recurringTasks: recurringTasks,
            pendingCount: pendingCount,
            conflictCount: conflictCount,
            failedCount: failedCount,
            errorSummary: errorSummary
        )
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
    let categories: [BackupImportCategory]
    let bills: [BackupImportBill]
    let recurringTasks: [BackupImportRecurringTask]
    let pendingCount: Int
    let conflictCount: Int
    let failedCount: Int
    let errorSummary: [String]
}

private enum ImportExportError: LocalizedError {
    case invalidBackupFile
    case unsupportedSchema(Int)
    case importEnvironmentUnavailable
    case importFailed(reason: String)

    var errorDescription: String? {
        switch self {
        case .invalidBackupFile:
            return "备份文件格式不正确"
        case .unsupportedSchema(let version):
            return "备份版本不兼容（schemaVersion: \(version)）"
        case .importEnvironmentUnavailable:
            return "导入环境不可用，请重启应用后重试"
        case .importFailed(let reason):
            return "导入失败：\(reason)"
        }
    }
}
