import Foundation

struct FileModal: Codable {
    var id: String
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
}

struct CollectionModal: Codable {
    var id: String
    var description: String
    var isPrivate: Bool
    var isHidden: Bool
    var created: Date
    var owner: String?
}

struct UserModal: Codable {
    var username: String
    var created: Date
}
