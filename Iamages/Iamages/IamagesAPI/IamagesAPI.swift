import Foundation
import Alamofire
import PromiseKit

struct IamagesInvalidResponseError: Error {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    public var localizedDescription: String {
        return message
    }
}

struct IamagesUnconvertableImageError: Error {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    public var localizedDescription: String {
        return message
    }
}

enum IamagesUploadableFormats: String {
    case png = "png"
    case jpeg = "jpeg"
}

enum IamagesUserModifiable: String, Equatable, Comparable {
    case biography = "UserBiography"
    case password = "UserPassword"
    case deleteAccount = "DeleteUser"
    
    static func <(lhs: IamagesUserModifiable, rhs: IamagesUserModifiable) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    static func ==(lhs: IamagesUserModifiable, rhs: IamagesUserModifiable) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

enum IamagesFileModifiable: String, Equatable, Comparable {
    case description = "FileDescription"
    case isNSFW = "FileNSFW"
    case isExcludeSearch = "FileExcludeSearch"
    case isPrivate = "FilePrivate"
    case deleteFile = "DeleteFile"
    
    static func <(lhs: IamagesFileModifiable, rhs: IamagesFileModifiable) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    static func ==(lhs: IamagesFileModifiable, rhs: IamagesFileModifiable) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

class IamagesAPI {
    let IAMAGES_APIROOT: String = "https://iamages.uber.space/iamages/api/"

    private func makeRequest(method: String, endpoint: String, body: [String: Any]?, encodedUserAuth: String?) -> Promise<String> {
        return Promise<String> { seal in
            var request: URLRequest = URLRequest(url: URL(string: IAMAGES_APIROOT + endpoint)!)
            if (encodedUserAuth != nil) {
                request.addValue("Basic " + encodedUserAuth!, forHTTPHeaderField: "Authorization")
            }
            if (body != nil) {
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONSerialization.data(withJSONObject: body!, options: [])
            }
            request.httpMethod = method
            AF.request(request)
                .validate()
                .responseString(encoding: .utf8, completionHandler: { response in
                    switch (response.result) {
                    case .success:
                        seal.fulfill(response.value!)
                    case .failure:
                        seal.reject(response.error!)
                    }
                })
        }
    }
    
    func get_root_latest() -> Promise<IamagesFileIDsResponse> {
        return Promise<IamagesFileIDsResponse> { seal in
            makeRequest(method: "GET", endpoint: "latest", body: nil, encodedUserAuth: nil).done({ response in
                guard let conformedResponse: IamagesFileIDsResponse = IamagesFileIDsResponse(JSONString: response) else {
                    seal.reject(IamagesInvalidResponseError("Could not conform response for /latest !"))
                    return
                }
                seal.fulfill(conformedResponse)
            }).catch({ error in
                seal.reject(error)
            })
        }
    }
    
    func get_root_info(id: Int, encodedUserAuth: String?) -> Promise<IamagesFileInformationResponse> {
        return Promise<IamagesFileInformationResponse> { seal in
            makeRequest(method: "GET", endpoint: "info/" + String(id) , body: nil, encodedUserAuth: encodedUserAuth).done({ response in
                guard let conformedResponse: IamagesFileInformationResponse = IamagesFileInformationResponse(JSONString: response) else {
                    seal.reject(IamagesInvalidResponseError("Could not conform response for /info/" + String(id) + " !"))
                    return
                }
                seal.fulfill(conformedResponse)
            }).catch({ error in
                seal.reject(error)
            })
        }
    }
    
    func get_root_infos(ids: IamagesFileIDsResponse, userAuth: IamagesUserAuth?) -> Promise<[IamagesFileInformationResponse]> {
        return Promise<[IamagesFileInformationResponse]> { seal in
            var requestBody: [String: AnyHashable] = [
                "FileIDs": ids.ids
            ]
            
            if userAuth != nil {
                requestBody["UserName"] = userAuth?.username
                requestBody["UserPassword"] = userAuth?.password
            }
            
            makeRequest(method: "POST", endpoint: "infos", body: requestBody, encodedUserAuth: nil).done({ response in
                var parsedResponse: [[String: Any]] = []
                do {
                    parsedResponse = try JSONSerialization.jsonObject(with: response.data(using: .utf8)!) as! [[String: Any]]
                } catch {
                    seal.reject(error)
                }
                var conformedResponses: [IamagesFileInformationResponse] = []
                for file in parsedResponse {
                    guard let conformedResponse: IamagesFileInformationResponse = IamagesFileInformationResponse(JSON: file) else {
                        seal.reject(IamagesInvalidResponseError("Could not conform response for /infos/ !"))
                        return
                    }
                    conformedResponses.append(conformedResponse)
                }
                seal.fulfill(conformedResponses)
            }).catch({ error in
                seal.reject(error)
            })
        }
    }
    
    func get_root_random() -> Promise<IamagesFileInformationResponse> {
        return Promise<IamagesFileInformationResponse> { seal in
            makeRequest(method: "GET", endpoint: "random/", body: nil, encodedUserAuth: nil).done({ response in
                guard let conformedResponse: IamagesFileInformationResponse = IamagesFileInformationResponse(JSONString: response) else {
                    seal.reject(IamagesInvalidResponseError("Could not conform response for /random/!"))
                    return
                }
                seal.fulfill(conformedResponse)
            }).catch({ error in
                seal.reject(error)
            })
        }
    }
    
    func get_root_embed(id: Int) -> URL {
        return URL(string: self.IAMAGES_APIROOT + "embed/" + String(id))!
    }
    
    func get_root_img(id: Int) -> URL {
        return URL(string: self.IAMAGES_APIROOT + "img/" + String(id))!
    }
    
    func get_root_thumb(id: Int) -> URL {
        return URL(string: self.IAMAGES_APIROOT + "thumb/" + String(id))!
    }
    
    func put_root_upload(information: IamagesUploadRequest, preferredUploadFormat: IamagesUploadableFormats, userAuth: IamagesUserAuth?) -> Promise<IamagesUploadResponse> {
        return Promise<IamagesUploadResponse> { seal in
            var requestBody: [String: AnyHashable] = [
                "FileDescription": information.description,
                "FileNSFW": information.isNSFW,
                "FileExcludeSearch": information.isExcludeSearch
            ]
            
            let b64Data: String?
            
            switch preferredUploadFormat {
            case .png:
                b64Data = information.img.pngData()?.base64EncodedString()
            case .jpeg:
                b64Data = information.img.jpegData(compressionQuality: 0)?.base64EncodedString()
            }

            if b64Data != nil {
                requestBody["FileData"] = b64Data
            } else {
                seal.reject(IamagesUnconvertableImageError("Could not convert an image to format '\(preferredUploadFormat.rawValue)'"))
            }
            
            if userAuth != nil {
                requestBody["UserName"] = userAuth?.username
                requestBody["UserPassword"] = userAuth?.password
                requestBody["FilePrivate"] = information.isPrivate
            }
            
            makeRequest(method: "PUT", endpoint: "upload", body: requestBody, encodedUserAuth: nil).done({ response in
                guard let conformedResponse: IamagesUploadResponse = IamagesUploadResponse(JSONString: response) else {
                    seal.reject(IamagesInvalidResponseError("Could not conform response for /upload !"))
                    return
                }
                
                seal.fulfill(conformedResponse)
            }).catch({ error in
                seal.reject(error)
            })
        }
    }
    
    func patch_root_modify(modifyRequest: IamagesFileModifyRequest, userAuth: IamagesUserAuth) -> Promise<Bool> {
        return Promise<Bool> { seal in
            var requestBody: [String: Any] = [
                "FileID": modifyRequest.id,
                "UserName": userAuth.username,
                "UserPassword": userAuth.password,
                "Modifications": [:]
            ]
            var requestedModifications: [IamagesFileModifiable] = []
            var modificationsDict: [String: AnyHashable] = [:]
            for (modification, value) in modifyRequest.modifications {
                modificationsDict[modification.rawValue] = value
                requestedModifications.append(modification)
            }
            requestBody["Modifications"] = modificationsDict
            makeRequest(method: "PATCH", endpoint: "modify", body: requestBody, encodedUserAuth: nil).done({ response in
                guard let conformedResponse: IamagesFileModifyResponse = IamagesFileModifyResponse(JSONString: response) else {
                    seal.reject(IamagesInvalidResponseError("Could not conform response for /modify !"))
                    return
                }
                var appliedModifications: [IamagesFileModifiable] = []
                for modification in conformedResponse.modifications {
                    appliedModifications.append(IamagesFileModifiable(rawValue: modification)!)
                }
                if requestedModifications.count == appliedModifications.count && requestedModifications.sorted() == appliedModifications.sorted() {
                    seal.fulfill(true)
                } else {
                    seal.reject(IamagesInvalidResponseError("Request modifications not found in response!"))
                }
            }).catch({ error in
                seal.reject(error)
            })
        }
    }
    
    func post_root_user_check(userAuth: IamagesUserAuth) -> Promise<Bool> {
        return Promise<Bool> { seal in
            makeRequest(method: "POST", endpoint: "user/check", body: ["UserName": userAuth.username, "UserPassword": userAuth.password], encodedUserAuth: nil).done({ response in
                guard let conformedResponse: IamagesUsernameOnlyResponse = IamagesUsernameOnlyResponse(JSONString: response) else {
                    seal.reject(IamagesInvalidResponseError("Could not conform response for /check !"))
                    return
                }
                if conformedResponse.username == userAuth.username {
                    seal.fulfill(true)
                } else {
                    seal.reject(IamagesUnauthenticatedUserError("The user couldn't be authenticated!"))
                }
            }).catch({ error in
                seal.reject(error)
            })
        }
    }
    
    func post_root_user_info(userAuth: IamagesUserAuth) -> Promise<IamagesUserInformationResponse> {
        return Promise<IamagesUserInformationResponse> { seal in
            makeRequest(method: "POST", endpoint: "user/info", body: ["UserName": userAuth.username], encodedUserAuth: nil).done({ response in
                guard let conformedResponse: IamagesUserInformationResponse = IamagesUserInformationResponse(JSONString: response) else {
                    seal.reject(IamagesInvalidResponseError("Could not conform response for /info/" + userAuth.username + " !"))
                    return
                }
                if conformedResponse.username == userAuth.username {
                    seal.fulfill(conformedResponse)
                } else {
                    seal.reject(IamagesUnauthenticatedUserError("The user couldn't be authenticated!"))
                }
            }).catch({ error in
                seal.reject(error)
            })
        }
    }
    
    func post_root_user_files(userAuth: IamagesUserAuth) -> Promise<IamagesFileIDsResponse> {
        return Promise<IamagesFileIDsResponse> { seal in
            makeRequest(method: "POST", endpoint: "user/files", body: ["UserName": userAuth.username, "UserPassword": userAuth.password], encodedUserAuth: nil).done({ response in
                guard let conformedResponse: IamagesFileIDsResponse = IamagesFileIDsResponse(JSONString: response) else {
                    seal.reject(IamagesInvalidResponseError("Could not conform response for /user/files !"))
                    return
                }
                seal.fulfill(conformedResponse)
            }).catch({ error in
                seal.reject(error)
            })
        }
    }
    
    func patch_root_user_modify(modifyRequest: IamagesUserModifyRequest, userAuth: IamagesUserAuth) -> Promise<Bool> {
        return Promise<Bool> { seal in
            var requestBody: [String: Any] = [
                "UserName": userAuth.username,
                "UserPassword": userAuth.password,
                "Modifications": [:]
            ]
            var requestedModifications: [IamagesUserModifiable] = []
            var modificationsDict: [String: String] = [:]
            for (modification, value) in modifyRequest.modifications {
                modificationsDict[modification.rawValue] = value
                requestedModifications.append(modification)
            }
            requestBody["Modifications"] = modificationsDict
            makeRequest(method: "PATCH", endpoint: "user/modify", body: requestBody, encodedUserAuth: nil).done({ response in
                guard let conformedResponse: IamagesUserModifyResponse = IamagesUserModifyResponse(JSONString: response) else {
                    seal.reject(IamagesInvalidResponseError("Could not conform response for /user/modify !"))
                    return
                }
                var appliedModifications: [IamagesUserModifiable] = []
                for modification in conformedResponse.modifications {
                    appliedModifications.append(IamagesUserModifiable(rawValue: modification)!)
                }
                if requestedModifications == appliedModifications {
                    seal.fulfill(true)
                } else {
                    seal.reject(IamagesInvalidResponseError("Request modifications not found in response!"))
                }
            }).catch({ error in
                seal.reject(error)
            })
        }
    }
    
    func put_root_user_new(userAuth: IamagesUserAuth) -> Promise<Bool> {
        return Promise<Bool> { seal in
            makeRequest(method: "PUT", endpoint: "user/new", body: ["UserName": userAuth.username, "UserPassword": userAuth.password], encodedUserAuth: nil).done({ response in
                guard let conformedResponse: IamagesUsernameOnlyResponse = IamagesUsernameOnlyResponse(JSONString: response) else {
                    seal.reject(IamagesInvalidResponseError("Could not conform response for /user/new !"))
                    return
                }
                if conformedResponse.username == userAuth.username {
                    seal.fulfill(true)
                } else {
                    seal.reject(IamagesInvalidResponseError("Username doesn't match!"))
                }
            }).catch({ error in
                seal.reject(error)
            })
        }
    }
}
