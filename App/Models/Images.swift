import Foundation
import CryptoKit
import UniformTypeIdentifiers
import SwiftUI

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

struct IamagesImageAndMetadataContainer: Identifiable {
    let id: String
    var isLoading: Bool = true
    var image: IamagesImage
    var metadataContainer: IamagesImageMetadataContainer?
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
