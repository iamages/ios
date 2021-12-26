import Foundation
import UniformTypeIdentifiers

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

enum CollectionModifiable {
    case description(String)
    case isHidden(Bool)
    case isPrivate(Bool)
    case addFile(String)
    case removeFile(String)
    
    var field: String {
        switch self {
        case .description(_):
            return "description"
        case .isPrivate(_):
            return "private"
        case .isHidden(_):
            return "hidden"
        case .addFile(_):
            return "add_file"
        case .removeFile(_):
            return "remove_file"
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
        case .addFile(let id):
            return id
        case .removeFile(let id):
            return id
        }
    }
}

struct FieldDataRequest: Encodable {
    let field: String
    let data: String
}

struct UploadJSONRequest: Encodable, Equatable, Hashable {
    var description: String
    var isNSFW: Bool
    var isPrivate: Bool
    var isHidden: Bool
    var url: URL?
    
    enum CodingKeys: String, CodingKey {
        case description
        case isNSFW = "nsfw"
        case isPrivate = "private"
        case isHidden = "hidden"
        case url = "upload_url"
    }
}

struct UploadFile {
    var image: Data
    var type: UTType
}

struct UploadFileRequest: Identifiable {
    let id: UUID = UUID()
    var info: UploadJSONRequest
    var file: UploadFile?
}

struct UploadFailedInfo: Identifiable {
    let id: UUID
    let request: UploadFileRequest
    let error: Error
}
