import Foundation

enum LoginErrors: Error {
    case invalidUsername
    case invalidPassword(Bool)
    case invalidEmail
    case signupComplete
}

extension LoginErrors: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidUsername:
            return NSLocalizedString("The provided username is invalid.", comment: "")
        case .invalidPassword(_):
            return NSLocalizedString("The provided password is invalid.", comment: "")
        case .invalidEmail:
            return NSLocalizedString("The provided email is invalid.", comment: "")
        case .signupComplete:
            return NSLocalizedString("Your account has been created.", comment: "")
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .invalidUsername:
            return NSLocalizedString("Make your username has at least 3 characters and no spaces before, in, or after itself.", comment: "")
        case .invalidPassword(let isSigningUp):
            var localizedString = NSLocalizedString("Your password needs to have at least 6 characters.", comment: "")
            if isSigningUp {
                localizedString += " " + NSLocalizedString("Do not use commonly guessable sequences, and consider a longer password.", comment: "")
            }
            return localizedString
        case .invalidEmail:
            return NSLocalizedString("A valid one should look like this: you@example.com", comment: "")
        case .signupComplete:
            return NSLocalizedString("Login to use your new account.", comment: "")
        }
    }
}

enum FileImportErrors: Error {
    case tooLarge(String, Int)
    case noSize(String)
    case unsupportedType(String, String)
    case noType(String)
    case loadPhotoFromLibraryFailure
}

extension FileImportErrors: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .tooLarge(let name, let size):
            return NSLocalizedString("'\(name)' is too large to be uploaded (\(ByteCountFormatter.string(from: Measurement(value: Double(size), unit: .bytes), countStyle: .decimal))MB > 30MB).", comment: "")
        case .noSize(let name):
            return NSLocalizedString("'\(name)' does not have file size information.", comment: "")
        case .unsupportedType(let name, let type):
            return NSLocalizedString("'\(name)' does not have a supported file type (\(type)).", comment: "")
        case .noType(let name):
            return NSLocalizedString("'\(name)' does not have file type information.", comment: "")
        case .loadPhotoFromLibraryFailure:
            return NSLocalizedString("Cannot load a file from your photo library.", comment: "")
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .tooLarge(_, _):
            return NSLocalizedString("Pick an image smaller than 30MB.", comment: "")
        case .unsupportedType(_, _):
            return NSLocalizedString("Pick an image that is a JPEG, PNG, GIF or WebP file.", comment: "")
        case .loadPhotoFromLibraryFailure:
            return NSLocalizedString("Check your internet connection, or iCloud system status.", comment: "")
        default:
            return nil
        }
    }
}

struct IdentifiableLocalizedError: Identifiable {
    var id: UUID = UUID()
    var error: LocalizedError
}

struct NoSaltError: LocalizedError {
    let errorDescription: String? = NSLocalizedString("Salt is missing.", comment: "")
}

struct PasswordMismatchError: LocalizedError {
    let errorDescription: String? = NSLocalizedString("Passwords don't match", comment: "")
    let recoverySuggestion: String? = NSLocalizedString("Check both passwords for mismatches.", comment: "")
}
