import Foundation

struct IamagesUser: Codable {
    let username: String
    let createdOn: Date
    
    enum CodingKeys: String, CodingKey {
        case username
        case createdOn = "created_on"
    }
}

struct IamagesUserToken: Codable {
    let accessToken: String
    let tokenType: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
    }
}

struct LastIamagesUserToken: Codable {
    let token: IamagesUserToken
    let date: Date
}

struct IamagesNewUser: Codable {
    var username: String
    var password: String
}
