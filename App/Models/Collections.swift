import Foundation

struct IamagesCollection: Codable, Identifiable, Hashable {
    let id: String
    let createdOn: Date
    let owner: String?
    var isPrivate: Bool
    var description: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case createdOn = "created_on"
        case owner
        case isPrivate = "is_private"
        case description
    }
}

struct NewIamagesCollection: Codable {
    var isPrivate: Bool
    var description: String
    var imageIDs: [String] = []
    
    enum CodingKeys: String, CodingKey {
        case isPrivate = "is_private"
        case description
        case imageIDs = "image_ids"
    }
}

struct AddIamagesCollectionNotification {
    var id: UUID? = nil
    let collection: IamagesCollection
}
