import Foundation

struct APIErrorDetails: Codable {
    let detail: String
}

enum APICommunicationErrors: Error {
    case invalidURL(URL?)
    case invalidResponse(URL?)
    case badResponse(Int, String)
    case invalidUploadRequest
    case notLoggedIn
    case noMIMEType(String)
    case noUnlockKey(String)
}

extension APICommunicationErrors: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return NSLocalizedString("Invalid URL: \(url?.absoluteString ?? "unknown")", comment: "")
        case .invalidResponse(let url):
            return NSLocalizedString("Could not parse response for '\(url?.absoluteString ?? "Unknown")'.", comment: "")
        case .badResponse(let code, let detail):
            return NSLocalizedString("Bad response code '\(code)' outside of range 200-299 (\(detail)).", comment: "")
        case .invalidUploadRequest:
            return NSLocalizedString("Upload request doesn't have an attached file.", comment: "")
        case .notLoggedIn:
            return NSLocalizedString("No logged in user to get token for.", comment: "")
        case .noMIMEType(let name):
            return NSLocalizedString("'\(name)' does not have a valid MIME type.", comment: "")
        case .noUnlockKey(let id):
            return NSLocalizedString("Unlock key not provided for '\(id)'", comment: "")
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .invalidUploadRequest:
            return NSLocalizedString("Add a file to the upload request.", comment: "")
        case .notLoggedIn:
            return NSLocalizedString("Please log in via Settings.", comment: "")
        case .noUnlockKey(_):
            return NSLocalizedString("Provide an unlock key to decrypt the image.", comment: "")
        default:
            return nil
        }
    }
}
