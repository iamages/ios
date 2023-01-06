import Foundation

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
