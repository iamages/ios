import Foundation

struct IamagesImage: Decodable {
    struct Lock: Decodable {
        let isLocked: Bool
        
        enum CodingKeys: String, CodingKey {
            case isLocked = "is_locked"
        }
    }
    
    struct File: Decodable {
        let typeExtension: String
        
        enum CodingKeys: String, CodingKey {
            case typeExtension = "type_extension"
        }
    }
    
    let id: String
    let isPrivate: Bool
    let lock: Lock
    let file: File
    
    enum CodingKeys: String, CodingKey {
        case id
        case isPrivate = "is_private"
        case lock
        case file
    }
}

struct IamagesImageMetadata: Decodable {
    let description: String
}
