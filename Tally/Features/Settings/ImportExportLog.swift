import Foundation

struct ImportExportLog: Identifiable, Codable, Equatable {
    enum Status: String, Codable {
        case success
        case warning
        case failure
    }

    let id: UUID
    let status: Status
    let title: String
    let createdAt: Date
    let count: Int
    let errors: Int

    init(
        id: UUID = UUID(),
        status: Status,
        title: String,
        createdAt: Date = Date(),
        count: Int,
        errors: Int
    ) {
        self.id = id
        self.status = status
        self.title = title
        self.createdAt = createdAt
        self.count = count
        self.errors = errors
    }
}

enum ImportExportLogStore {
    static let key = "tally.importexport.log"
    private static let limit = 20

    static func load(defaults: UserDefaults = .standard) -> [ImportExportLog] {
        guard let data = defaults.data(forKey: key) else { return [] }
        let logs = (try? JSONDecoder().decode([ImportExportLog].self, from: data)) ?? []
        return Array(logs.prefix(limit))
    }

    static func save(_ logs: [ImportExportLog], defaults: UserDefaults = .standard) {
        let capped = Array(logs.prefix(limit))
        guard let data = try? JSONEncoder().encode(capped) else { return }
        defaults.set(data, forKey: key)
    }

    static func prepend(_ log: ImportExportLog, to logs: [ImportExportLog]) -> [ImportExportLog] {
        Array(([log] + logs).prefix(limit))
    }
}
