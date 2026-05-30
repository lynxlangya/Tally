import Foundation

enum ProfileIdentityStore {
    static let nameKey = "profileName"
    static let avatarDataKey = "profileAvatarData"
    static let defaultName = "Tally"
    static let nameLimit = 16

    static func limitedInput(_ name: String) -> String {
        String(name.prefix(nameLimit))
    }

    static func displayName(for storedName: String) -> String {
        let trimmed = storedName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? defaultName : trimmed
    }

    static func persistedName(for input: String) -> String {
        displayName(for: limitedInput(input))
    }
}
