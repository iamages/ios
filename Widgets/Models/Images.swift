import Foundation

struct IamagesImage: Decodable {
    struct Lock: Decodable {
        let isLocked: Bool
        
        enum CodingKeys: String, CodingKey {
            case isLocked = "is_locked"
        }
    }
    
    let id: String
    let isPrivate: Bool
    let lock: Lock
    
    enum CodingKeys: String, CodingKey {
        case id
        case isPrivate = "is_private"
        case lock
    }
}

struct IamagesImageMetadata: Decodable {
    let description: String
}
