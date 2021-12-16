import Foundation
import SwiftUI
import KeychainAccess
import Kingfisher

struct AppUser: Encodable {
    var username: String
    var password: String
}

enum APICommunicationErrors: Error {
    case invalidURL(String)
    case badResponse(Int)
}

extension APICommunicationErrors: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return NSLocalizedString("Invalid URL: \(url)", comment: "")
        case .badResponse(let code):
            return NSLocalizedString("Bad response code '\(code)' outside of range 200-299.", comment: "")
        }
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case delete = "DELETE"
}

@MainActor
class APIDataObservable: ObservableObject {
    private let jsond: JSONDecoder = JSONDecoder()
    private let jsone: JSONEncoder = JSONEncoder()
    private let keychain: Keychain = Keychain()

    let loadLimit: Int = 5
    var apiRoot: String = "http://localhost:9999/iamages/api/v3"
    
    @AppStorage("isNSFWEnabled") var isNSFWEnabled: Bool = true

    @Published var currentAppUser: AppUser?
    @Published var currentAppUserInformation: IamagesUser?
    @Published var currentAppUserAuthHeader: String?
    @Published var isLoggedIn: Bool = false
    
    init () {
        self.jsond.dateDecodingStrategy = .customISO8601
        self.jsone.dateEncodingStrategy = .customISO8601

        if let username = self.keychain["iamages_username"],
           let password = self.keychain["iamages_password"] {
            let user = AppUser(
                username: username,
                password: password
            )
            Task {
                do {
                    try await self.checkAppUser(user: user)
                } catch {
                    print(error)
                }
            }
        }
        KingfisherManager.shared.defaultOptions = [.requestModifier(AnyModifier { request in
            var r = request
            r.setValue(self.currentAppUserAuthHeader, forHTTPHeaderField: "Authorization")
            return r
        })]
    }
    
    func getURLRequest(_ endpoint: String, method: HTTPMethod, body: Data?, auth: String?) throws -> URLRequest {
        guard let url: URL = URL(string: self.apiRoot + endpoint) else {
            throw APICommunicationErrors.invalidURL(self.apiRoot + endpoint)
        }

        var request = URLRequest(url: url)
        if endpoint != "/file/upload" {
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        } else {
            request.addValue("multipart/form-data", forHTTPHeaderField: "Content-Type")
        }
        if auth != nil {
            request.addValue(auth!, forHTTPHeaderField: "Authorization")
        }

        request.httpMethod = method.rawValue
        request.httpBody = body
        
        return request
    }
    
    func makeRequest(_ endpoint: String, method: HTTPMethod, body: Data?, auth: String?) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(
            for: try self.getURLRequest(
                endpoint,
                method: method,
                body: body,
                auth: auth
            )
        )
        
        guard let statusCode: Int = (response as? HTTPURLResponse)?.statusCode else {
            throw APICommunicationErrors.badResponse(0)
        }
        
        if 200...299 ~= statusCode {
            return data
        } else {
            throw APICommunicationErrors.badResponse(statusCode)
        }
    }
    
    func getLatestFiles (startDate: Date?) async throws -> [IamagesFile] {
        return try self.jsond.decode(
            [IamagesFile].self,
            from: try await makeRequest(
                "/feed/files/latest",
                method: .post,
                body: try self.jsone.encode(
                    DatePaginationRequest(
                        limit: self.loadLimit,
                        startDate: startDate
                    )
                ),
                auth: nil
            )
        )
    }
    
    func getPopularFiles () async throws -> [IamagesFile] {
        return try self.jsond.decode(
            [IamagesFile].self,
            from: try await makeRequest(
                "/feed/files/popular",
                method: .get,
                body: nil,
                auth: nil
            )
        )
    }
    
    func getRandomFile () async throws -> IamagesFile {
        return try self.jsond.decode(
            IamagesFile.self,
            from: try await self.makeRequest(
                "/feed/files/random?nsfw=\(self.isNSFWEnabled ? "1" : "0")",
                method: .get,
                body: nil,
                auth: nil
            )
        )
    }
    
    func getLatestCollections (startDate: Date?) async throws -> [IamagesCollection] {
        return try self.jsond.decode(
            [IamagesCollection].self,
            from: try await self.makeRequest(
                "/feed/collections/latest",
                method: .post,
                body: try self.jsone.encode(
                    DatePaginationRequest(
                        limit: self.loadLimit,
                        startDate: startDate
                    )
                ),
                auth: nil
            )
        )
    }
    
    func getFileThumbnailURL (id: String) -> URL {
        return URL(string: "\(self.apiRoot)/file/\(id)/thumb")!
    }
    
    func getFileImageURL (id: String) -> URL {
        return URL(string: "\(self.apiRoot)/file/\(id)/img")!
    }
    
    func getFileEmbedURL (id: String) -> URL {
        return URL(string: self.apiRoot + "/file/\(id)/embed")!
    }
    
    func modifyFile (id: String, modify: FileModifiable) async throws {
        try await self.makeRequest(
            "/file/\(id)/modify",
            method: .patch,
            body: try self.jsone.encode(
                FileModifyRequest(
                    field: modify.field,
                    data: modify.data
                )
            ),
            auth: self.currentAppUserAuthHeader
        )
    }
    
    func deleteFile (file: IamagesFile) async throws {
        try await self.makeRequest(
            "/file/\(file.id)/delete",
            method: .delete,
            body: nil,
            auth: self.currentAppUserAuthHeader
        )
    }
    
    func getCollectionEmbedURL (id: String) -> URL {
        return URL(string: self.apiRoot + "/collection/\(id)/embed")!
    }
    
    func getCollectionFiles (id: String, limit: Int?, startDate: Date?) async throws -> [IamagesFile] {
        return try self.jsond.decode(
            [IamagesFile].self,
            from: try await self.makeRequest(
                "/collection/\(id)/files",
                method: .post,
                body: try self.jsone.encode(
                    DatePaginationRequest(
                        limit: limit ?? self.loadLimit,
                        startDate: startDate
                    )
                ),
                auth: self.currentAppUserAuthHeader
            )
        )
    }
    
    func deleteCollection (id: String) async throws {
        try await self.makeRequest(
            "/collection/\(id)/delete",
            method: .delete,
            body: nil,
            auth: self.currentAppUserAuthHeader
        )
    }
    
    func getSearchFiles (description: String, startDate: Date?, username: String?) async throws -> [IamagesFile] {
        return try self.jsond.decode(
            [IamagesFile].self,
            from: try await self.makeRequest(
                "/search/files\((username != nil) ? "?username=\(username!.urlEncode())" : "")",
                method: .post,
                body: try self.jsone.encode(
                    FileCollectionSearchRequest(
                        description: description,
                        limit: self.loadLimit,
                        startDate: startDate
                    )
                ),
                auth: self.currentAppUserAuthHeader
            )
        )
    }
    
    func getSearchCollections (description: String, startDate: Date?, username: String?) async throws -> [IamagesCollection] {
        return try self.jsond.decode(
            [IamagesCollection].self,
            from: try await self.makeRequest(
                "/search/collections\((username != nil) ? "?username=\(username!.urlEncode())" : "")",
                method: .post,
                body: try self.jsone.encode(
                    FileCollectionSearchRequest(
                        description: description,
                        limit: self.loadLimit,
                        startDate: startDate
                    )
                ),
                auth: self.currentAppUserAuthHeader
            )
        )
    }
    
    func getSearchUsers (username: String, startDate: Date?) async throws -> [IamagesUser] {
        return try self.jsond.decode(
            [IamagesUser].self,
            from: try await self.makeRequest(
                "/search/users",
                method: .post,
                body: try self.jsone.encode(
                    UserSearchRequest(
                        username: username,
                        limit: self.loadLimit,
                        startDate: startDate
                    )
                ),
                auth: nil
            )
        )
    }

    func getUserProfilePictureURL (username: String) -> URL {
        return URL(string: self.apiRoot + "/user/\(username.urlEncode())/pfp")!
    }
    
    func getUserInformation (username: String) async throws -> IamagesUser {
        return try self.jsond.decode(
            IamagesUser.self,
            from: try await self.makeRequest(
                "/user/\(username.urlEncode())/info",
                method: .get,
                body: nil,
                auth: self.currentAppUserAuthHeader
            )
        )
    }
    
    func getUserFiles (username: String, startDate: Date?) async throws -> [IamagesFile] {
        return try self.jsond.decode(
            [IamagesFile].self,
            from: try await self.makeRequest(
                "/user/\(username.urlEncode())/files",
                method: .post,
                body: try self.jsone.encode(
                    DatePaginationRequest(
                        limit: self.loadLimit,
                        startDate: startDate
                    )
                ),
                auth: self.currentAppUserAuthHeader
            )
        )
    }
    
    func getUserCollections (username: String, startDate: Date?) async throws -> [IamagesCollection] {
        return try self.jsond.decode(
            [IamagesCollection].self,
            from: try await self.makeRequest(
                "/user/\(username.urlEncode())/collections",
                method: .post,
                body: try self.jsone.encode(
                    DatePaginationRequest(
                        limit: self.loadLimit,
                        startDate: startDate
                    )
                ),
                auth: self.currentAppUserAuthHeader
            )
        )
    }
    
    func modifyAppUser (modify: UserModifiable) async throws {
        try await self.makeRequest(
            "/user/modify",
            method: .patch,
            body: self.jsone.encode(
                UserModifyRequest(
                    field: modify.field,
                    data: modify.data
                )
            ),
            auth: self.currentAppUserAuthHeader
        )
        switch modify {
        case .password(let password):
            self.currentAppUser?.password = password
        case .pfp(let pfp):
            self.currentAppUserInformation?.pfp = pfp
        }
    }
    
    func logoutAppUser () throws {
        try keychain.remove("iamages_username")
        try keychain.remove("iamages_password")
        self.currentAppUser = nil
        self.currentAppUserInformation = nil
        self.currentAppUserAuthHeader = nil
        self.isLoggedIn = false
    }
    
    func setKeychain (username: String, password: String) throws {
        try self.keychain.set(username, key: "iamages_username")
        try self.keychain.set(password, key: "iamages_password")
    }
    
    func checkAppUser(user: AppUser) async throws {
        let authHeader: String = "Basic " + "\(user.username):\(user.password)".data(using: .utf8)!.base64EncodedString()
        try await self.makeRequest(
            "/user/check",
            method: .get,
            body: nil,
            auth: authHeader
        )
        self.currentAppUser = user
        self.currentAppUserAuthHeader = authHeader
        self.currentAppUserInformation = try await self.getUserInformation(username: currentAppUser!.username)
        self.isLoggedIn = true
    }
    
    func saveAppUser(username: String, password: String) async throws {
        try await self.checkAppUser(user: AppUser(
            username: username,
            password: password
        ))
        try self.setKeychain(username: username, password: password)
    }
    
    func makeNewAppUser (username: String, password: String) async throws {
        let user: AppUser = AppUser(username: username, password: password)
        let userInformation: IamagesUser = try self.jsond.decode(
            IamagesUser.self,
            from: try await self.makeRequest(
                "/user/new",
                method: .post,
                body: try self.jsone.encode(user),
                auth: nil
            )
        )
        self.currentAppUser = user
        self.currentAppUserAuthHeader = "Basic " + "\(user.username):\(user.password)".data(using: .utf8)!.base64EncodedString()
        self.currentAppUserInformation = userInformation

        self.isLoggedIn = true

        try self.setKeychain(username: username, password: password)
    }
    
    func deleteAppUser () async throws {
        try await self.makeRequest(
            "/user/delete",
            method: .delete,
            body: nil,
            auth: self.currentAppUserAuthHeader
        )
        try self.logoutAppUser()
    }
    
    func privatizeAppUser (method: UserPrivatizable) async throws {
        try await self.makeRequest(
            "/user/privatize",
            method: .post,
            body: try self.jsone.encode(
                UserPrivatizeRequest(
                    method: method
                )
            ),
            auth: self.currentAppUserAuthHeader
        )
    }
}