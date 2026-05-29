import Foundation

enum FeatureErrorMessage {
    static func message(for error: Error, fallback: String) -> String {
        if let repositoryError = error as? RepositoryError {
            return message(for: repositoryError, fallback: fallback)
        }

        if let localizedError = error as? LocalizedError,
           let message = localizedError.errorDescription?.trimmingCharacters(in: .whitespacesAndNewlines),
           !message.isEmpty {
            return message
        }

        return fallback
    }

    private static func message(for error: RepositoryError, fallback: String) -> String {
        switch error {
        case .notFound:
            return TallyLocalization.text("error_not_found", locale: LanguageManager.shared.currentLocale)
        case .invalidData:
            return TallyLocalization.text("error_invalid_data", locale: LanguageManager.shared.currentLocale)
        case .forbidden:
            return fallback
        }
    }
}
