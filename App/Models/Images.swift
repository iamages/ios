import Foundation
import CryptoKit
import UniformTypeIdentifiers

struct Thumbnail: Codable {
    let is_computing: Bool
    let compute_attempts: Int
}

enum LockVersion: Int, Codable {
    case aes128gcm_argon2 = 1
}

struct Lock: Codable {
    var is_locked: Bool
    var version: LockVersion
}

struct IamagesImage: Codable {
    let owner: String?
    let isPrivate: Bool
    let lock: Lock
    let thumbnail: Thumbnail
    
    enum CodingKeys: String, CodingKey {
        case owner
        case isPrivate = "is_private"
        case lock
        case thumbnail
    }
}

struct IamagesImageMetadata: Codable {
    var description: String
    let width: Int
    let height: Int
    let createdOn: Date
    
    enum CodingKeys: String, CodingKey {
        case description
        case width
        case height
        case createdOn = "created_on"
    }
}

extension IamagesImageMetadata: RawRepresentable {
    public init?(rawValue: String) {
       guard let data = rawValue.data(using: .utf8),
             let result = try? JSONDecoder().decode(IamagesImageMetadata.self, from: data) else {
           return nil
       }
       self = result
   }

   public var rawValue: String {
       guard let data = try? JSONEncoder().encode(self),
           let result = String(data: data, encoding: .utf8)
       else {
           return "[]"
       }
       return result
   }
}

struct IamagesUploadInformation: Codable, Identifiable {
    let id: UUID = UUID()
    var description: String = NSLocalizedString("No description provided.", comment: "")
    var isPrivate: Bool = false
    var isLocked: Bool = false
    var lockKey: String = ""
    
    enum CodingKeys: String, CodingKey {
        case description
        case isPrivate = "is_private"
        case isLocked = "is_locked"
        case lockKey = "lock_key"
    }
}

struct IamagesUploadFile {
    var filename: String
    var data: Data
    var type: UTType
}

struct IamagesUploadContainer: Identifiable {
    let id: UUID = UUID()
    var information: IamagesUploadInformation = IamagesUploadInformation()
    var file: IamagesUploadFile
}
