import Foundation

struct IamagesUser: Codable {
    let username: String
    var email: String?
    let createdOn: Date
    
    enum CodingKeys: String, CodingKey {
        case username
        case email
        case createdOn = "created_on"
    }
}

struct IamagesNewUser: Codable {
    var username: String
    var password: String
}

struct IamagesPasswordReset: Codable {
    let email: String
    let code: String
    let newPassword: String
    
    enum CodingKeys: String, CodingKey {
        case email
        case code
        case newPassword = "new_password"
    }
}

struct IamagesUserEdit: Codable {
    enum Changeable: String, Codable {
        case password
        case email
    }
    
    let change: Changeable
    let to: String?
}
