import Foundation

// Credits:
// https://www.avanderlee.com/swiftui/error-alert-presenting/

struct LocalizedAlertError: LocalizedError, Equatable, Identifiable {
    let id = UUID()
    
    let underlyingError: LocalizedError
    var errorDescription: String? {
        underlyingError.errorDescription
    }
    var recoverySuggestion: String? {
        underlyingError.recoverySuggestion
    }
    
    init?(error: Error?) {
        guard let localizedError = error as? LocalizedError else { return nil }
        underlyingError = localizedError
    }
    
    static func ==(lhs: LocalizedAlertError, rhs: LocalizedAlertError) -> Bool {
        return lhs.id == rhs.id
    }
}
