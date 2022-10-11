import Foundation
import KeychainAccess
import MultipartFormData
import CryptoKit
import Argon2Swift
import GRDB

fileprivate struct EncryptedBlob {
    let salt: Data
    let nonce: Data
    let data: Data
    let tag: Data
}

fileprivate enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case delete = "DELETE"
}

fileprivate enum HTTPContentType: String {
    case json = "application/json; charset=utf-8"
    case encodedForm = "application/x-www-form-urlencoded"
    case multipart = "multipart/form-data"
}

class ViewModel: ObservableObject {
    private let jsone = JSONEncoder()
    private let jsond = JSONDecoder()
    
    private let keychain = Keychain(accessGroup: "group.me.jkelol111.Iamages")

    #if DEBUG
    private let apiBaseURL: URL = URL(string: "http://localhost:8000")!
    #else
    private let apiBaseURL: URL = URL(string: "https://api.iamages.app")!
    #endif

    @KeychainStorage("userInformation") var userInformation: IamagesUser?
    @KeychainStorage("lastUserToken") var lastUserToken: LastIamagesUserToken?
    @Published var isUploadDetailVisible: Bool = false
    @Published var isNewCollectionSheetVisible: Bool = false
    @Published var selectedImage: IamagesImage?
    
    private func fetchData(
        _ endpoint: String,
        method: HTTPMethod,
        body: Data? = nil,
        contentType: HTTPContentType = .json,
        headers: [String: String] = [:],
        requiresAuth: Bool = false
    ) async throws -> Data {
        var request = URLRequest(
            url: self.apiBaseURL.appending(path: endpoint)
        )
        request.httpMethod = method.rawValue

        request.httpBody = body
        request.addValue("Content-Type", forHTTPHeaderField: contentType.rawValue)

        if requiresAuth {
            guard let lastUserToken = self.lastUserToken else {
                try await fetchUserToken()
                return try await fetchData(
                    endpoint,
                    method: method,
                    body: body,
                    headers: headers,
                    requiresAuth: requiresAuth
                )
            }
            if Date.now.timeIntervalSince(lastUserToken.date) > 1800 {
                try await fetchUserToken()
            }
            request.addValue("Bearer \(lastUserToken.token.accessToken)", forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw APICommunicationErrors.invalidResponse(request.url)
        }
        if response.statusCode < 200 || response.statusCode > 299 {
            throw APICommunicationErrors.badResponse(response.statusCode, String(data: data, encoding: .utf8))
        }
        return data
    }
    
    private func fetchUserToken() async throws {
        if let username = try self.keychain.get("username"),
           let password = try self.keychain.get("password") {
            let newLastUserToken = LastIamagesUserToken(
                token: try self.jsond.decode(
                    IamagesUserToken.self,
                    from: try await fetchData(
                        "/users/token",
                        method: .post,
                        body: "username=\(username)&password=\(password)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)?.data(using: .utf8),
                        contentType: .encodedForm
                    )
                ),
                date: Date.now
            )
            self.lastUserToken = newLastUserToken
        } else {
            throw APICommunicationErrors.notLoggedIn
        }
    }
    
    private func getUserInformation() async throws {
        self.userInformation = try self.jsond.decode(
            IamagesUser.self,
            from: try await self.fetchData(
                "/users/",
                method: .get,
                requiresAuth: true
            )
        )
    }
    
    func login(username: String, password: String) async throws {
        do {
            try self.keychain.set(username, key: "username")
            try self.keychain.set(password, key: "password")
            try await self.fetchUserToken()
        } catch {
            try self.keychain.remove("username")
            try self.keychain.remove("password")
            throw error
        }
        try await self.getUserInformation()
    }
    
    func signup(username: String, password: String) async throws {
        try await self.fetchData(
            "/users/",
            method: .post,
            body: self.jsone.encode(
                IamagesNewUser(
                    username: username,
                    password: password
                )
            )
        )
    }
    
    private func decryptAndVerify(
        blob: EncryptedBlob,
        key: String
    ) throws -> Data {
        let key = SymmetricKey(
            data: try Argon2Swift.hashPasswordBytes(
                password: key.data(using: .utf8)!,
                salt: Salt(bytes: blob.salt),
                length: 16
            ).hashData()
        )
        let nonce = try AES.GCM.Nonce(data: blob.nonce)
        let sealedBox = try AES.GCM.SealedBox(
            nonce: nonce,
            ciphertext: blob.data,
            tag: blob.tag
        )
        return try AES.GCM.open(sealedBox, using: key)
    }
    
    private func fetchEncryptedBlob(
        _ endpoint: String,
        method: HTTPMethod,
        isPrivate: Bool
    ) async throws -> EncryptedBlob {
        var request = URLRequest(
            url: URL(string: "\(self.apiBaseURL)\(endpoint)")!
        )
        request.httpMethod = method.rawValue
        request.addValue("", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              let saltHeader = httpResponse.value(forHTTPHeaderField: "X-Iamages-Lock-Salt"),
              let salt = Data(base64Encoded: saltHeader),
              let nonceHeader = httpResponse.value(forHTTPHeaderField: "X-Iamages-Lock-Nonce"),
              let nonce = Data(base64Encoded: nonceHeader),
              let tagHeader = httpResponse.value(forHTTPHeaderField: "X-Iamages-Lock-Salt"),
              let tag = Data(base64Encoded: tagHeader) else {
            throw URLError(.badServerResponse)
        }
        
        return EncryptedBlob(
            salt: salt,
            nonce: nonce,
            data: data,
            tag: tag
        )
    }
    
    func getImageMetadata(id: String) async throws {
        
    }
}
