import Foundation

struct IamagesCollectionMetadata: Hashable {
    var description: String
}

struct IamagesCollection: Identifiable, Hashable {
    let id: String
    let createdOn: Date
    let owner: String?
    var isPrivate: Bool
    var metadata: IamagesCollectionMetadata
    
    enum CodingKeys: String, CodingKey {
        case id
        case createdOn = "created_on"
        case owner
        case isPrivate = "is_private"
        case metadata
    }
}
