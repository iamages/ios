import Foundation
import UniformTypeIdentifiers

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
