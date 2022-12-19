import Foundation

struct IamagesCollection: Codable, Identifiable, Hashable {
    struct Metadata: Codable, Hashable {
        var description: String
    }
    
    let id: String
    let createdOn: Date
    let owner: String?
    var isPrivate: Bool
    var metadata: Metadata
    
    enum CodingKeys: String, CodingKey {
        case id
        case createdOn = "created_on"
        case owner
        case isPrivate = "is_private"
        case metadata
    }
}

struct IamagesCollectionEdit: Codable {
    enum Changable: String, Codable {
        case description
        case isPrivate = "is_private"
        case addImages = "add_images"
        case removeImages = "remove_images"
    }
    let change: Changable
    let to: BoolOrString
    
    enum CodingKeys: String, CodingKey {
        case change
        case to
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.change, forKey: .change)
        switch self.to {
        case .bool(let bool):
            try container.encode(bool, forKey: .to)
        case .string(let string):
            try container.encode(string, forKey: .to)
        case .stringArray(let stringArray):
            try container.encode(stringArray, forKey: .to)
        }
    }
}
