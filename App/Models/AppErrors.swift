import Foundation

// Credits:
// https://www.avanderlee.com/swiftui/error-alert-presenting/

struct LocalizedAlertError: LocalizedError {
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
}

enum APICommunicationErrors: Error {
    case invalidURL(URL)
    case invalidResponse(URL?)
    case badResponse(Int, String?)
    case invalidUploadRequest
    case notLoggedIn
}

extension APICommunicationErrors: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return NSLocalizedString("Invalid URL: \(url.absoluteString)", comment: "")
        case .invalidResponse(let url):
            return NSLocalizedString("Could not parse response for '\(url?.absoluteString ?? "Unknown")'.", comment: "")
        case .badResponse(let code, let detail):
            return NSLocalizedString("Bad response code '\(code)' outside of range 200-299 (\(detail ?? "Unknown error")).", comment: "")
        case .invalidUploadRequest:
            return NSLocalizedString("Upload request doesn't have an attached file.", comment: "")
        case .notLoggedIn:
            return NSLocalizedString("No logged in user to get token for.", comment: "")
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .invalidUploadRequest:
            return NSLocalizedString("Add a file to the upload request.", comment: "")
        case .notLoggedIn:
            return NSLocalizedString("Please log in via Settings.", comment: "")
        default:
            return nil
        }
    }
}

enum LoginErrors: Error {
    case invalidUsername
    case invalidPassword
    case signupComplete
}

extension LoginErrors: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidUsername:
            return NSLocalizedString("The provided username is invalid.", comment: "")
        case .invalidPassword:
            return NSLocalizedString("The provided password is invalid.", comment: "")
        case .signupComplete:
            return NSLocalizedString("Your account has been created.", comment: "")
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .invalidUsername:
            return NSLocalizedString("Make your username has at least 3 characters and no spaces before, in, or after itself.", comment: "")
        case .invalidPassword:
            return NSLocalizedString("Your password needs to have at least 6 characters. Do not use commonly guessable sequences, and consider a longer password.", comment: "")
        case .signupComplete:
            return NSLocalizedString("Login to use your new account.", comment: "")
        }
    }
}
