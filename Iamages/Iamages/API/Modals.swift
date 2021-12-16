import Foundation

struct IamagesFile: Decodable, Identifiable, Equatable, Hashable {
    let id: String
    var description: String
    var isNSFW: Bool
    var isPrivate: Bool
    var isHidden: Bool
    var created: Date
    var mime: String
    var width: Int
    var height: Int
    var owner: String?
    var views: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case description
        case isNSFW = "nsfw"
        case isPrivate = "private"
        case isHidden = "hidden"
        case created
        case mime
        case width
        case height
        case owner
        case views
    }
}

struct IamagesCollection: Decodable, Identifiable, Equatable {
    let id: String
    var description: String
    var isPrivate: Bool
    var isHidden: Bool
    var created: Date
    var owner: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case description
        case isPrivate = "private"
        case isHidden = "hidden"
        case created
        case owner
    }
}

struct IamagesUser: Decodable, Hashable {
    let username: String
    var created: Date
    var pfp: String?
    
    enum CodingKeys: String, CodingKey {
        case username
        case created
        case pfp
    }
}

struct DatePaginationRequest: Encodable {
    var limit: Int
    var startDate: Date?
    
    enum CodingKeys: String, CodingKey {
        case limit
        case startDate = "start_date"
    }
}

struct FileCollectionSearchRequest: Encodable {
    var description: String
    var limit: Int
    var startDate: Date?
    
    enum CodingKeys: String, CodingKey {
        case description
        case limit
        case startDate = "start_date"
    }
}

struct UserSearchRequest: Encodable {
    var username: String
    var limit: Int
    var startDate: Date?
    
    enum CodingKeys: String, CodingKey {
        case username
        case limit
        case startDate = "start_date"
    }
}

enum UserModifiable {
    case password(String)
    case pfp(String)
    
    var field: String {
        switch self {
        case .password(_):
            return "password"
        case .pfp(_):
            return "pfp"
        }
    }
    
    var data: String {
        switch self {
        case .password(let password):
            return password
        case .pfp(let pfp):
            return pfp
        }
    }
}

struct UserModifyRequest: Encodable {
    let field: String
    let data: String
}

enum UserPrivatizable: String, Codable {
    case privatize_all
    case hide_all
}

struct UserPrivatizeRequest: Encodable {
    let method: UserPrivatizable
}

enum FileModifiable {
    case description(String)
    case isNSFW(Bool)
    case isHidden(Bool)
    case isPrivate(Bool)
    
    var field: String {
        switch self {
        case .description(_):
            return "description"
        case .isNSFW(_):
            return "nsfw"
        case .isHidden(_):
            return "hidden"
        case .isPrivate(_):
            return "private"
        }
    }
    
    var data: String {
        switch self {
        case .description(let description):
            return description
        case .isNSFW(let isNSFW):
            return isNSFW ? "1" : "0"
        case .isHidden(let isHidden):
            return isHidden ? "1" : "0"
        case .isPrivate(let isPrivate):
            return isPrivate ? "1" : "0"
        }
    }
}

struct FileModifyRequest: Encodable {
    let field: String
    let data: String
}

enum CollectionModifiable {
    case description(String)
    case isHidden(Bool)
    case isPrivate(Bool)
    
    var field: String {
        switch self {
        case .description(_):
            return "description"
        case .isPrivate(_):
            return "private"
        case .isHidden(_):
            return "hidden"
        }
    }
    
    var data: String {
        switch self {
        case .description(let description):
            return description
        case .isPrivate(let isPrivate):
            return isPrivate ? "1" : "0"
        case .isHidden(let isHidden):
            return isHidden ? "1" : "0"
        }
    }
}

struct CollectionModifyRequest: Encodable {
    let field: String
    let data: String
}

struct UploadFileInfoRequest: Encodable {
    var description: String
    var isNSFW: Bool
    var isPrivate: Bool
    var isHidden: Bool
}

struct UploadFileFullRequest {
    var info: UploadFileInfoRequest
    var uploadFile: Data
}
