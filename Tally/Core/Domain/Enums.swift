import Foundation

enum BillType: String, CaseIterable, Identifiable, Codable {
    case income
    case expense

    var id: String { rawValue }
}

enum ExportFormat: String, CaseIterable, Identifiable, Codable {
    case csv
    case pdf

    var id: String { rawValue }
    var fileExtension: String { rawValue }
}

enum ThemeMode: String, CaseIterable, Identifiable, Codable {
    case system
    case light
    case dark

    var id: String { rawValue }
}
