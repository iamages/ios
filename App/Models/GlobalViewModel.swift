import Foundation
import KeychainAccess
import MultipartFormData
import CryptoKit
import Argon2Swift
import GRDB
import UniformTypeIdentifiers
import Nuke
import SharedWithYou

class UploadProgress: NSObject, URLSessionTaskDelegate {
    private let cb: (Double) -> Void
    
    init(cb: @escaping (Double) -> Void) {
        self.cb = cb
    }
    
    internal func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
    ) {
        self.cb(Double(totalBytesSent) / Double(totalBytesExpectedToSend))
    }
}

@MainActor
final class GlobalViewModel: NSObject, ObservableObject, URLSessionTaskDelegate, SWHighlightCenterDelegate {
    enum AuthenticationStrategy {
        case whenPossible
        case required
        case none
    }
    
    private struct EncryptedBlob {
        let salt: Data
        let nonce: Data
        let data: Data
        let tag: Data
    }

    private let keychain = Keychain.getIamagesKeychain()
    private let addAuthStrategies: [AuthenticationStrategy] = [
        .whenPossible, .required
    ]
    
    let jsone = JSONEncoder()
    let jsond = JSONDecoder()
    
    let acceptedFileTypes: [String] = [
        "image/jpeg",
        "image/png",
        "image/gif",
        "image/webp"
    ]

    @Published var userInformation: IamagesUser?
    
    private var lastUserToken: LastIamagesUserToken?
    var isLoggedIn: Bool { self.lastUserToken != nil }
    
    @Published var isSettingsPresented: Bool = false
    @Published var selectedSettingsView: AppSettingsViews?
    
    #if !targetEnvironment(macCatalyst)
    @Published var isUploadsPresented: Bool = false
    @Published var isNewCollectionPresented: Bool = false
    #endif
    
    var highlightCenter = SWHighlightCenter()
    
    override init() {
        super.init()
        
        self.jsone.dateEncodingStrategy = .iso8601
        self.jsond.dateDecodingStrategy = .iso8601
        
        ImagePipeline.shared = ImagePipeline(configuration: .withDataCache)
        (ImagePipeline.shared.configuration.dataLoader as? DataLoader)?.delegate = self
        
        self.highlightCenter.delegate = self
        
        do {
            if let userInformation = try self.keychain.getDataWithKey(.userInformation) {
                self.userInformation = try self.jsond.decode(IamagesUser.self, from: userInformation)
            }
            if let lastUserToken = try self.keychain.getDataWithKey(.lastUserToken) {
                self.lastUserToken = try self.jsond.decode(LastIamagesUserToken.self, from: lastUserToken)
            }
        } catch {
            print("Error fetching logged in user information. Maybe you're not logged in yet?")
            print(error)
        }
    }
    
    private func addUserTokenToRequest(to request: inout URLRequest) async throws {
        if self.lastUserToken == nil || Date.now.timeIntervalSince(self.lastUserToken!.date) > 1800 {
            try await self.fetchUserToken()
        }
        request.addValue("\(self.lastUserToken!.token.tokenType) \(self.lastUserToken!.token.accessToken)", forHTTPHeaderField: "Authorization")
    }
    
    // MARK: Delegate methods
    nonisolated internal func highlightCenterHighlightsDidChange(_ highlightCenter: SWHighlightCenter) {
        highlightCenter.highlights.forEach { highlight in
            print("Received a new highlight with URL: \(highlight.url)")
        }
    }
    
    internal func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest
    ) async -> URLRequest? {
        var newRequest = request
        if let header = response.value(forHTTPHeaderField: "X-Iamages-Image-Private") as? NSString,
           header.boolValue
        {
            do {
                try await self.addUserTokenToRequest(to: &newRequest)
            } catch {
                print(error)
            }
        }
        return newRequest
    }
    
    func fetchData(
        _ endpoint: String,
        queryItems: [URLQueryItem] = [],
        method: HTTPMethod,
        body: Data? = nil,
        contentType: HTTPContentType = .json,
        headers: [String: String] = [:],
        authStrategy: AuthenticationStrategy = .none,
        useUpload: Bool = false,
        uploadProgressCb: ((Double) -> Void)? = nil
    ) async throws -> (Data, HTTPURLResponse) {
        var url: URL = URL.apiRootUrl.appendingPathComponent(endpoint)
        url.append(queryItems: queryItems)
        
        var request = URLRequest(
            url: url
        )
        request.httpMethod = method.rawValue

        if !useUpload {
            request.httpBody = body
        }
        
        request.addValue(contentType.rawValue, forHTTPHeaderField: "Content-Type")
        
        if self.addAuthStrategies.contains(authStrategy) && self.isLoggedIn {
            try await self.addUserTokenToRequest(to: &request)
        }

        let data: Data
        let response: URLResponse

        if useUpload {
            guard let body, let uploadProgressCb else {
                throw APICommunicationErrors.invalidUploadRequest
            }
            (data, response) = try await URLSession.shared.upload(
                for: request,
                from: body,
                delegate: UploadProgress(cb: uploadProgressCb)
            )
        } else {
            (data, response) = try await URLSession.shared.data(for: request)
        }
        
        guard let response = response as? HTTPURLResponse else {
            throw APICommunicationErrors.invalidResponse(request.url)
        }
        if response.statusCode < 200 || response.statusCode > 299 {
            let detail: String
            do {
                detail = try self.jsond.decode(APIErrorDetails.self, from: data).detail
            } catch {
                detail = String(decoding: data, as: UTF8.self)
            }
            throw APICommunicationErrors.badResponse(response.statusCode, detail)
        }

        return (data, response)
    }
    
    private func fetchUserToken() async throws {
        if let username = try self.keychain.getStringWithKey(.username),
           let password = try self.keychain.getStringWithKey(.password) {
            let newLastUserToken = LastIamagesUserToken(
                token: try self.jsond.decode(
                    IamagesUserToken.self,
                    from: try await fetchData(
                        "/users/token",
                        method: .post,
                        body: "username=\(username)&password=\(password)&grant_type=password".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)?.data(using: .utf8),
                        contentType: .encodedForm
                    ).0
                ),
                date: Date.now
            )
            self.lastUserToken = newLastUserToken
            try self.keychain.setDataWithKey(self.jsone.encode(newLastUserToken), key: .lastUserToken)
            try await self.getUserInformation()
        } else {
            throw APICommunicationErrors.notLoggedIn
        }
    }
    
    func getUserInformation() async throws {
        let userInformation: IamagesUser = try self.jsond.decode(
            IamagesUser.self,
            from: try await self.fetchData(
                "/users/",
                method: .get,
                authStrategy: .required
            ).0
        )
        self.userInformation = userInformation
        try self.keychain.setDataWithKey(self.jsone.encode(userInformation), key: .userInformation)
    }
    
    func login(username: String, password: String) async throws {
        do {
            try self.keychain.setStringWithKey(username, key: .username)
            try self.keychain.setStringWithKey(password, key: .password)
            try await self.fetchUserToken()
        } catch {
            try self.keychain.removeWithKey(.username)
            try self.keychain.removeWithKey(.password)
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
    
    func logout() throws {
        try self.keychain.removeAll()
        self.userInformation = nil
        self.lastUserToken = nil
    }
    
    func hashKey(for key: String, salt: Data) throws -> Argon2SwiftResult {
        return try Argon2Swift.hashPasswordBytes(
            password: key.data(using: .utf8)!,
            salt: Salt(bytes: salt),
            iterations: 3,
            memory: 65536,
            parallelism: 4,
            length: 16,
            type: .id
        )
    }
    
    private func decryptAndVerify(
        blob: EncryptedBlob,
        key: String
    ) throws -> Data {
        let key = SymmetricKey(
            data: try self.hashKey(for: key, salt: blob.salt).hashData()
        )
        let nonce = try AES.GCM.Nonce(data: blob.nonce)
        let sealedBox = try AES.GCM.SealedBox(
            nonce: nonce,
            ciphertext: blob.data,
            tag: blob.tag
        )
        return try AES.GCM.open(sealedBox, using: key)
    }
    
    private func getEncryptedBlob(
        data: Data,
        response: HTTPURLResponse
    ) throws -> EncryptedBlob {
        guard let saltHeader = response.value(forHTTPHeaderField: "X-Iamages-Lock-Salt"),
              let salt = Data(base64Encoded: saltHeader),
              let nonceHeader = response.value(forHTTPHeaderField: "X-Iamages-Lock-Nonce"),
              let nonce = Data(base64Encoded: nonceHeader),
              let tagHeader = response.value(forHTTPHeaderField: "X-Iamages-Lock-Tag"),
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
    
    func getImagePublicMetadata(id: String) async throws -> IamagesImage {
        return try self.jsond.decode(
            IamagesImage.self,
            from: try await self.fetchData(
                "/images/\(id)",
                queryItems: [
                    URLQueryItem(name: "type", value: "public")
                ],
                method: .get,
                authStrategy: .whenPossible
            ).0
        )
    }
    
    func getImagePrivateMetadata(
        for image: IamagesImage,
        key: String? = nil
    ) async throws -> IamagesImageMetadataContainer {
        let (data, response): (Data, HTTPURLResponse) = try await self.fetchData(
            "/images/\(image.id)/metadata",
            method: .get,
            authStrategy: image.isPrivate ? .required : .none
        )
        var actualData: Data = data
        var salt: Data? = nil
        if image.lock.isLocked {
            guard let key else {
                throw APICommunicationErrors.notLoggedIn
            }
            let blob = try self.getEncryptedBlob(data: data, response: response)
            actualData = try self.decryptAndVerify(
                blob: blob,
                key: key
            )
            salt = blob.salt
        }
        return IamagesImageMetadataContainer(
            data: try self.jsond.decode(IamagesImageMetadata.self, from: actualData),
            salt: salt
        )
    }
    
    func getThumbnailRequest(for image: IamagesImage) -> ImageRequest {
        var request: URLRequest = URLRequest(url: URL.apiRootUrl.appending(path: "/thumbnails/\(image.id)"))
        if image.isPrivate && self.isLoggedIn {
            if Date.now.timeIntervalSince(self.lastUserToken!.date) > 1800 {
                Task {
                    try await self.fetchUserToken()
                }
            }
            request.addValue("\(self.lastUserToken!.token.tokenType) \(self.lastUserToken!.token.accessToken)", forHTTPHeaderField: "Authorization")
        }
        return ImageRequest(urlRequest: request, processors: [.resize(width: 64)])
    }
    
    func getImageRequest(for image: IamagesImage, key: String? = nil) -> ImageRequest {
        let path: String = "/images/\(image.id)/download"
        var options: ImageRequest.Options = []
        if image.lock.isLocked {
            options.insert(.disableDiskCache)
            options.insert(.disableMemoryCache)
        }
        return ImageRequest(
            id: path,
            data: {
                let (data, response): (Data, HTTPURLResponse) = try await self.fetchData(
                    path,
                    method: .get,
                    authStrategy: image.isPrivate ? .required : .none
                )
                if image.lock.isLocked {
                    guard let key else {
                        throw APICommunicationErrors.notLoggedIn
                    }
                    return try await self.decryptAndVerify(
                        blob: try self.getEncryptedBlob(data: data, response: response),
                        key: key
                    )
                }
                return data
            },
            options: options
        )
    }
    
    func uploadImage(
        for upload: IamagesUploadContainer,
        uploadProgressCb: @escaping (Double) -> Void
    ) async throws -> IamagesImage {
        let mimeType: [String] = upload.file.type.components(separatedBy: "/")
        
        let form: MultipartFormData = try MultipartFormData(
            boundary: try Boundary(uncheckedBoundary: "iamages")
        ) {
            try Subpart {
                ContentDisposition(name: "information")
                ContentType(mediaType: .applicationJson)
            } body: {
                try self.jsone.encode(upload.information)
            }
            
            Subpart {
                ContentDisposition(name: "file", filename: "image.bin")
                ContentType(mediaType: MediaType(type: mimeType[0], subtype: mimeType[1]))
            } body: {
                upload.file.data
            }
        }
        
        return try self.jsond.decode(
            IamagesImage.self,
            from: try await self.fetchData(
                "/images/",
                method: .post,
                body: form.httpBody,
                contentType: .multipart,
                authStrategy: .whenPossible,
                useUpload: true,
                uploadProgressCb: uploadProgressCb
            ).0
        )
    }
}
