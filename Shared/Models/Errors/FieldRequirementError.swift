import Foundation

enum FieldRequirementError: Error {
    case imageDescription
    case missingLockKey
    case imageToLarge
}

extension FieldRequirementError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .imageDescription:
            return NSLocalizedString("Image description requirement", comment: "")
        case .missingLockKey:
            return NSLocalizedString("Lock key missing", comment: "")
        case .imageToLarge:
            return NSLocalizedString("Image too large", comment: "")
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .imageDescription:
            return NSLocalizedString("Has to be between 1-255 characters.", comment: "")
        case .missingLockKey:
            return NSLocalizedString("A lock key must be provided.", comment: "")
        case .imageToLarge:
            return NSLocalizedString("Image is too large. The limit is 30MB.", comment: "")
        }
    }
}
