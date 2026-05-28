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
            return "未找到对应数据，请返回后重试"
        case .invalidData:
            return "本地数据异常，请稍后重试"
        case .forbidden:
            return fallback
        }
    }
}
