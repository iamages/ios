import Foundation
import CryptoKit
import UniformTypeIdentifiers
import SwiftUI

struct IamagesImage: Codable, Identifiable, Hashable {
    struct Lock: Codable, Hashable {
        enum Version: Int, Codable {
            case aes128gcm_argon2 = 1
        }

        var isLocked: Bool
        var version: Version?
        var upgradable: Bool?
        
        enum CodingKeys: String, CodingKey {
            case isLocked = "is_locked"
            case version
            case upgradable
        }
    }
    
    struct Thumbnail: Codable, Hashable {
        let isComputing: Bool
        let isUnavailable: Bool
        
        enum CodingKeys: String, CodingKey {
            case isComputing = "is_computing"
            case isUnavailable = "is_unavailable"
        }
    }
    
    let id: String
    let createdOn: Date
    let owner: String?
    var isPrivate: Bool
    let contentType: UTType
    var lock: Lock
    let thumbnail: Thumbnail?
    
    enum CodingKeys: String, CodingKey {
        case id
        case createdOn = "created_on"
        case owner
        case isPrivate = "is_private"
        case contentType = "content_type"
        case lock
        case thumbnail
    }
    
    init(
        id: String,
        createdOn: Date,
        owner: String? = nil,
        isPrivate: Bool,
        contentType: UTType,
        lock: Lock,
        thumbnail: Thumbnail? = nil
    ) {
        self.id = id
        self.createdOn = createdOn
        self.owner = owner
        self.isPrivate = isPrivate
        self.contentType = contentType
        self.lock = lock
        self.thumbnail = thumbnail
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(String.self, forKey: .id)
        self.createdOn = try container.decode(Date.self, forKey: .createdOn)
        self.owner = try container.decodeIfPresent(String.self, forKey: .owner)
        self.isPrivate = try container.decode(Bool.self, forKey: .isPrivate)
        
        guard let contentType = UTType(mimeType: try container.decode(String.self, forKey: .contentType)) else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [CodingKeys.contentType],
                    debugDescription: "Could not convert MIME type string into UTType."
                )
            )
        }
        self.contentType = contentType

        self.lock = try container.decode(Lock.self, forKey: .lock)
        self.thumbnail = try container.decodeIfPresent(Thumbnail.self, forKey: .thumbnail)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.createdOn, forKey: .createdOn)
        try container.encodeIfPresent(self.owner, forKey: .owner)
        try container.encode(self.isPrivate, forKey: .isPrivate)
        guard let contentType = self.contentType.preferredMIMEType else {
            throw EncodingError.invalidValue(
                self.contentType,
                .init(
                    codingPath: [CodingKeys.contentType],
                    debugDescription: "Could not convert UTType into MIME type string."
                )
            )
        }
        try container.encode(contentType, forKey: .contentType)
        try container.encode(self.lock, forKey: .lock)
        try container.encodeIfPresent(self.thumbnail, forKey: .thumbnail)
    }
}

struct IamagesImageMetadata: Codable {
    var description: String
    let width: Int
    let height: Int
    var realContentType: UTType? = nil
    
    enum CodingKeys: String, CodingKey {
        case description
        case width
        case height
        case realContentType = "real_content_type"
    }
    
    init(description: String, width: Int, height: Int, realContentType: UTType?) {
        self.description = description
        self.width = width
        self.height = height
        self.realContentType = realContentType
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.description = try container.decode(String.self, forKey: .description)
        self.width = try container.decode(Int.self, forKey: .width)
        self.height = try container.decode(Int.self, forKey: .height)
        if let realContentType = try container.decodeIfPresent(String.self, forKey: .realContentType),
           let realUTType = UTType(mimeType: realContentType){
            self.realContentType = realUTType
        }
    }
}

struct IamagesImageMetadataContainer {
    var data: IamagesImageMetadata
    var salt: Data? = nil
}

// MARK: Image uploads
struct IamagesUploadContainer: Identifiable, Hashable {
    let id: UUID = UUID()
    var information: IamagesUploadInformation = IamagesUploadInformation()
    var file: IamagesUploadFile
    var progress: Double = 0.0
    var isUploading: Bool = false
}

// MARK: Image editing
struct IamagesImageEdit: Codable {
    struct Notification {
        let id: String
        let edit: IamagesImageEdit
    }
    
    struct Response: Codable {
        let ok: Bool
        let lockVersion: IamagesImage.Lock.Version?
        
        enum CodingKeys: String, CodingKey {
            case ok
            case lockVersion = "lock_version"
        }
    }
    
    enum Changable: String, Codable {
        case isPrivate = "is_private"
        case lock = "lock"
        case description = "description"
    }
    
    let change: Changable
    let to: BoolOrString
    var metadataLockKey: Data? = nil
    var imageLockKey: Data? = nil
    var lockVersion: IamagesImage.Lock.Version? = nil
    
    enum CodingKeys: String, CodingKey {
        case change
        case to
        case metadataLockKey = "metadata_lock_key"
        case imageLockKey = "image_lock_key"
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.change, forKey: .change)
        switch self.to {
        case .bool(let bool):
            try container.encode(bool, forKey: .to)
        case .string(let string):
            try container.encode(string, forKey: .to)
        default:
            break
        }
        try container.encodeIfPresent(self.metadataLockKey?.base64EncodedString(), forKey: .metadataLockKey)
        try container.encodeIfPresent(self.imageLockKey?.base64EncodedString(), forKey: .imageLockKey)
    }
}
