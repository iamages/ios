import Foundation
import ObjectMapper

struct IamagesFileIDsResponse: Equatable, Mappable {
    var ids: [Int]
    
    init?(map: Map) {
        guard let ids: [Int] = map["FileIDs"].value() else {
            print("FileID not found in response!")
            return nil
        }
        
        self.ids = ids
    }
    
    mutating func mapping(map: Map) {
        ids <- map["FileIDs"]
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

struct IamagesUsernameOnlyResponse: Equatable, Mappable {
    var username: String
    
    init?(map: Map) {
        guard let username: String = map["UserName"].value() else{
            print("Missing username attribute!")
            return nil
        }

        self.username = username
    }
    
    mutating func mapping(map: Map) {
        username <- map["UserName"]
    }
}

struct IamagesUserInformationResponse: Equatable, Mappable {
    var username: String
    var biography: String?
    var createdDate: String
    
    init?(map: Map) {
        guard let username: String = map["UserName"].value(),
              let createdDate: String = map["UserInfo.UserCreatedDate"].value() else {
            print("Missing user information attribute!")
            return nil
        }
        
        self.username = username
        self.createdDate = createdDate
    }
    
    mutating func mapping(map: Map) {
        username <- map["UserName"]
        biography <- map["UserInfo.UserBiography"]
        createdDate <- map["UserInfo.UserCreatedDate"]
    }
}

struct IamagesUserModifyResponse: Mappable {
    var username: String
    var modifications: [String]
    
    init?(map: Map) {
        guard let username: String = map["UserName"].value(),
              let modifications: [String] = map["Modifications"].value() else {
            print("Missing modification information attribute!")
            return nil
        }
        
        self.username = username
        self.modifications = modifications
    }
    
    mutating func mapping(map: Map) {
        username <- map["UserName"]
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
