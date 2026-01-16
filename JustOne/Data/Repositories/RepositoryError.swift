import Foundation

enum RepositoryError: Error {
    case notFound
    case invalidData(field: String)
}
