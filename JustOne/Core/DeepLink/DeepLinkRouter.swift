import Foundation

enum DeepLinkRoute: Equatable {
    case quickEntry
    case home
    case statistics
}

enum DeepLinkRouter {
    static func parse(_ url: URL) -> DeepLinkRoute? {
        guard url.scheme == "justone" else { return nil }
        let host = url.host ?? ""
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let target = host.isEmpty ? path : host
        switch target {
        case "quickEntry":
            return .quickEntry
        case "home":
            return .home
        case "statistics":
            return .statistics
        default:
            return nil
        }
    }
}
