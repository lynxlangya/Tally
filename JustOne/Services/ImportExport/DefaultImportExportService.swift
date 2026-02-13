import Foundation

struct DefaultImportExportService: ImportExportService {
    private let billRepository: BillRepository
    private let categoryRepository: CategoryRepository
    private let recurringRepository: RecurringRepository
    private let fileManager: FileManager
    private let nowProvider: () -> Date
    private let calendar: Calendar

    init(
        billRepository: BillRepository,
        categoryRepository: CategoryRepository,
        recurringRepository: RecurringRepository,
        fileManager: FileManager = .default,
        nowProvider: @escaping () -> Date = Date.init
    ) {
        self.billRepository = billRepository
        self.categoryRepository = categoryRepository
        self.recurringRepository = recurringRepository
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
        throw ServiceError.notImplemented
    }

    func previewImportCSV(from fileURL: URL) async throws -> ImportPreview {
        throw ServiceError.notImplemented
    }

    func importBackup(from fileURL: URL) async throws -> ImportResult {
        throw ServiceError.notImplemented
    }

    func importCSV(from fileURL: URL) async throws -> ImportResult {
        throw ServiceError.notImplemented
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
