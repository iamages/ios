import Foundation
import KeychainAccess

extension Keychain {
    static func getIamagesKeychain() -> Keychain {
        // FIXME: iCloud keychain still being used while synchronizable == false
        #if DEBUG
        return Keychain(
            service: "me.jkelol111.Iamages",
            accessGroup: "group.me.jkelol111.Iamages"
        )
        .synchronizable(false) // Disable iCloud keychain sharing
        #else
        return Keychain(
            server: URL.apiRootUrl.absoluteString,
            protocolType: .https,
            accessGroup: "group.me.jkelol111.Iamages"
        )
        .synchronizable(false) // Disable iCloud keychain sharing
        #endif
    }
    
    func setStringWithKey(_ value: String, key: IamagesKeychainKeys) throws {
        try self.label(key.label)
            .comment(key.comment)
            .set(value, key: key.rawValue)
    }
    
    func setDataWithKey(_ value: Data, key: IamagesKeychainKeys) throws {
        try self.label(key.label)
            .comment(key.comment)
            .set(value, key: key.rawValue)
    }
    
    func getStringWithKey(_ key: IamagesKeychainKeys) throws -> String? {
        return try self.getString(key.rawValue)
    }
    
    func getDataWithKey(_ key: IamagesKeychainKeys) throws -> Data? {
        return try self.getData(key.rawValue)
    }
    
    func removeWithKey(_ key: IamagesKeychainKeys) throws {
        try self.remove(key.rawValue)
    }
}

enum IamagesKeychainKeys: String {
    case username
    case password
    case userInformation
    case lastUserToken
}

extension IamagesKeychainKeys {
    var label: String {
        switch self {
        case .username:
            return "Iamages app user's username"
        case .password:
            return "Iamages app user's password"
        case .userInformation:
            return "Iamages app user's information"
        case .lastUserToken:
            return "Iamages app user's last access token"
        }
    }
    
    var comment: String {
        switch self {
        case .username:
            return "Currently logged in user's username."
        case .password:
            return "Currently logged in user's password."
        case .userInformation:
            return "Currently logged in user's information."
        case .lastUserToken:
            return "Currently logged in user's last access token and refresh date."
        }
    }
}
