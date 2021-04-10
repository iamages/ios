import Foundation
import ObjectMapper

class IamagesFileIDsResponse: Mappable {
    var ids: [Int]
    
    required init?(map: Map) {
        guard let ids: [Int] = map["FileIDs"].value() else {
            print("FileID not found in response!")
            return nil
        }
        
        self.ids = ids
    }
    
    func mapping(map: Map) {
        ids <- map["FileIDs"]
    }
}

class IamagesSearchResponse: IamagesFileIDsResponse {
    var description: String = ""
    
    required init?(map: Map) {
        super.init(map: map)
        
        guard let description: String = map["FileDescription"].value() else {
            print("Missing description attribute!")
            return
        }
        
        self.description = description
    }
    
    override func mapping(map: Map) {
        super.mapping(map: map)
        description <- map["FileDescription"]
    }
}

struct IamagesFileInformationResponse: Identifiable, Equatable, Mappable {
    var id: Int
    var description: String
    var isNSFW: Bool
    var isPrivate: Bool
    var mime: String
    var width: Int
    var height: Int
    var createdDate: String
    var isExcludeSearch: Bool
    
    init?(map: Map) {
        guard let id: Int = map["FileID"].value(),
              let description: String = map["FileDescription"].value(),
              let isNSFW: Bool = map["FileNSFW"].value(),
              let isPrivate: Bool = map["FilePrivate"].value(),
              let mime: String = map["FileMime"].value(),
              let width: Int = map["FileWidth"].value(),
              let height: Int = map["FileHeight"].value(),
              let createdDate: String = map["FileCreatedDate"].value(),
              let isExcludeSearch: Bool = map["FileExcludeSearch"].value() else {
            print("Missing file information attribute!")
            return nil
        }
        
        self.id = id
        self.description = description
        self.isNSFW = isNSFW
        self.isPrivate = isPrivate
        self.mime = mime
        self.width = width
        self.height = height
        self.createdDate = createdDate
        self.isExcludeSearch = isExcludeSearch
    }
    
    mutating func mapping(map: Map) {
        id <- map["FileID"]
        description <- map["FileDescription"]
        isNSFW <- map["FileNSFW"]
        isPrivate <- map["FilePrivate"]
        mime <- map["FileMime"]
        width <- map["FileWidth"]
        height <- map["FileHeight"]
        createdDate <- map["FileCreatedDate"]
        isExcludeSearch <- map["FileExcludeSearch"]
    }
}

struct IamagesUploadResponse: Identifiable, Mappable, Hashable {
    var id: Int
    
    init?(map: Map) {
        guard let id: Int = map["FileID"].value() else {
            print("Missing FileID attribute!")
            return nil
        }
        
        self.id = id
    }
    
    mutating func mapping(map: Map) {
        id <- map["FileID"]
    }
}

class IamagesUsernameOnlyResponse: Mappable, Equatable {
    var username: String
    
    required init?(map: Map) {
        guard let username: String = map["UserName"].value() else{
            print("Missing username attribute!")
            return nil
        }

        self.username = username
    }
    
    func mapping(map: Map) {
        username <- map["UserName"]
    }
    
    static func ==(lhs: IamagesUsernameOnlyResponse, rhs: IamagesUsernameOnlyResponse) -> Bool {
        return lhs.username == rhs.username
    }
}

class IamagesUserInformationResponse: IamagesUsernameOnlyResponse {
    var biography: String?
    var createdDate: String = NSLocalizedString("No created date found.", comment: "")

    required init?(map: Map) {
        super.init(map: map)

        guard let createdDate: String = map["UserInfo.UserCreatedDate"].value() else {
            print("Missing user information attribute!")
            return
        }
        
        self.createdDate = createdDate
        self.biography = map["UserInfo.UserBiography"].value()
    }
    
    override func mapping(map: Map) {
        super.mapping(map: map)
        biography <- map["UserInfo.UserBiography"]
        createdDate <- map["UserInfo.UserCreatedDate"]
    }
}

class IamagesUserModifyResponse: IamagesUsernameOnlyResponse {
    var modifications: [String] = []

    required init?(map: Map) {
        super.init(map: map)

        guard let modifications: [String] = map["Modifications"].value() else {
            print("Missing modification information attribute!")
            return
        }

        self.modifications = modifications
    }

    override func mapping(map: Map) {
        super.mapping(map: map)

        modifications <- map["Modifications"]
    }
}

struct IamagesFileModifyResponse: Mappable {
    var id: Int
    var modifications: [String]
    
    init?(map: Map) {
        guard let id: Int = map["FileID"].value(),
              let modifications: [String] = map["Modifications"].value() else {
            print("Missing modification information attribute!")
            return nil
        }
        
        self.id = id
        self.modifications = modifications
    }
    
    mutating func mapping(map: Map) {
        id <- map["FileID"]
        modifications <- map["Modifications"]
    }
}
