import Foundation
import KeychainSwift
import struct Kingfisher.AnyModifier

struct IamagesUnauthenticatedUserError: Error {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    public var localizedDescription: String {
        return message
    }
}

struct IamagesUserAuth: Equatable {
    var username: String
    var password: String
    init(username: String, password: String) {
        self.username = username
        self.password = password
    }
}

struct IamagesUserInformation: Equatable {
    var auth: IamagesUserAuth
    var biography: String
    var createdDate: String
    init(auth: IamagesUserAuth, biography: String, createdDate: String) {
        self.auth = auth
        self.biography = biography
        self.createdDate = createdDate
    }
}

class IamagesUserAuthHelpers {
    let keychain = KeychainSwift()
    
    func getEncodedUserAuth(userAuth: IamagesUserAuth) -> String {
        return (userAuth.username + ":" + userAuth.password).data(using: .utf8)!.base64EncodedString(options: [])
    }
    
    func getRequestModifier(encodedUserAuth: String) -> AnyModifier {
        return AnyModifier { request in
            var r = request
            r.setValue("Basic " + encodedUserAuth, forHTTPHeaderField: "Authorization")
            return r
        }
    }

    func getUserAuthFromKeychain() -> IamagesUserAuth {
        return IamagesUserAuth(username: keychain.get("username") ?? NSLocalizedString("No username", comment: ""), password: keychain.get("password") ?? "")
    }

    func saveUserAuthToKeychain(userAuth: IamagesUserAuth) throws {
        keychain.set(userAuth.username, forKey: "username")
        keychain.set(userAuth.password, forKey: "password")
    }

    func deleteUserAuthInKeychain() throws {
        keychain.clear()
    }

    func modifyUserAuthInKeychain(userAuth: IamagesUserAuth) throws {
        try saveUserAuthToKeychain(userAuth: userAuth)
    }
}
