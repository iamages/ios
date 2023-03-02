import Foundation
import UniformTypeIdentifiers

struct IamagesImage: Codable, Identifiable, Hashable {
    struct Lock: Codable, Hashable {
        enum Version: Int, Codable {
            case aes128gcm_argon2 = 1
            
            var friendlyName: String {
                switch self {
                case .aes128gcm_argon2:
                    return NSLocalizedString("AES-128 GCM with Argon2 derived key (\(self.rawValue))", comment: "")
                }
            }
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
    
    struct File: Codable, Hashable {
        var contentType: UTType
        var typeExtension: String
        var salt: Data? = nil
        
        enum CodingKeys: String, CodingKey {
            case contentType = "content_type"
            case typeExtension = "type_extension"
            case salt
        }
        
        init(contentType: UTType, typeExtension: String, salt: Data? = nil) {
            self.contentType = contentType
            self.typeExtension = typeExtension
            self.salt = salt
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            guard let contentType = UTType(mimeType: try container.decode(String.self, forKey: .contentType)) else {
                throw DecodingError.dataCorrupted(
                    .init(
                        codingPath: [CodingKeys.contentType],
                        debugDescription: "Could not convert MIME type string into UTType."
                    )
                )
            }
            self.contentType = contentType
            self.typeExtension = try container.decode(String.self, forKey: .typeExtension)
            if let salt = try container.decodeIfPresent(String.self, forKey: .salt),
               let saltData = salt.data(using: .utf8)
            {
                self.salt = saltData
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
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
            try container.encode(self.typeExtension, forKey: .typeExtension)
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
    var file: File
    var lock: Lock
    var thumbnail: Thumbnail?
    
    enum CodingKeys: String, CodingKey {
        case id
        case createdOn = "created_on"
        case owner
        case isPrivate = "is_private"
        case file
        case lock
        case thumbnail
    }
    
    init(
        id: String,
        createdOn: Date,
        owner: String? = nil,
        isPrivate: Bool,
        file: File,
        lock: Lock,
        thumbnail: Thumbnail? = nil
    ) {
        self.id = id
        self.createdOn = createdOn
        self.owner = owner
        self.isPrivate = isPrivate
        self.file = file
        self.lock = lock
        self.thumbnail = thumbnail
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.createdOn = try container.decode(Date.self, forKey: .createdOn)
        self.owner = try container.decodeIfPresent(String.self, forKey: .owner)
        self.isPrivate = try container.decode(Bool.self, forKey: .isPrivate)
        self.file = try container.decode(File.self, forKey: .file)
        self.lock = try container.decode(Lock.self, forKey: .lock)
        self.thumbnail = try container.decodeIfPresent(Thumbnail.self, forKey: .thumbnail)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.createdOn, forKey: .createdOn)
        try container.encodeIfPresent(self.owner, forKey: .owner)
        try container.encode(self.isPrivate, forKey: .isPrivate)
        try container.encode(self.file, forKey: .file)
        try container.encode(self.lock, forKey: .lock)
        try container.encodeIfPresent(self.thumbnail, forKey: .thumbnail)
    }
}
