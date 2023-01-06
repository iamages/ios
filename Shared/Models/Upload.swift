import SwiftUI
import KeychainAccess
import MultipartFormData

struct IamagesUploadInformation: Codable, Identifiable, Hashable {
    let id: UUID = UUID()
    var description: String = ""
    var isPrivate: Bool = false
    var isLocked: Bool = false
    var lockKey: String = ""
    
    enum CodingKeys: String, CodingKey {
        case description
        case isPrivate = "is_private"
        case isLocked = "is_locked"
        case lockKey = "lock_key"
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.description, forKey: .description)
        try container.encode(self.isPrivate, forKey: .isPrivate)
        try container.encode(self.isLocked, forKey: .isLocked)
        if self.isLocked && !self.lockKey.isEmpty {
            try container.encode(self.lockKey, forKey: .lockKey)
        }
    }
}

struct IamagesUploadFile: Hashable {
    var data: Data
    var type: String
}

struct NoImageDataError: LocalizedError {
    let errorDescription: String? = NSLocalizedString("Could not load image data.", comment: "")
    let recoverySuggestion: String? = NSLocalizedString("Make sure your image is a JPEG, PNG, GIF or WebP file.", comment: "")
}

final class UploadViewModel: NSObject, ObservableObject, URLSessionTaskDelegate {
    private let keychain = Keychain.getIamagesKeychain()
    private let jsond = JSONDecoder()
    private let jsone = JSONEncoder()
    
    @Published var information: IamagesUploadInformation = IamagesUploadInformation()
    @Published var file: IamagesUploadFile?
    
    @Published var isUploading: Bool = false
    @Published var progress: Double = 0.0
    
    override init() {
        self.jsond.dateDecodingStrategy = .iso8601
        self.jsone.dateEncodingStrategy = .iso8601
    }
    
    internal func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
    ) {
        self.progress = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
    }
    
    func checkLoggedIn() -> Bool {
        do {
            return try self.keychain.getStringWithKey(.username) != nil
        } catch {
            print(error)
            return false
        }
    }
    
    func upload() async throws {
        self.isUploading = true

        var uploadRequest = URLRequest(url: .apiRootUrl.appending(path: "/images", directoryHint: .isDirectory))
        uploadRequest.httpMethod = HTTPMethod.post.rawValue
        uploadRequest.addValue(HTTPContentType.multipart.rawValue, forHTTPHeaderField: "Content-Type")
        
        var lastUserToken: LastIamagesUserToken?
        if let tokenData = try self.keychain.getDataWithKey(.lastUserToken) {
            lastUserToken = try self.jsond.decode(LastIamagesUserToken.self, from: tokenData)
            if Date.now.timeIntervalSince(lastUserToken!.date) > 1800 {
                guard let username = try self.keychain.getStringWithKey(.username),
                      let password = try self.keychain.getStringWithKey(.password) else {
                    throw APICommunicationErrors.notLoggedIn
                }
                var tokenRequest = URLRequest(url: .apiRootUrl.appending(path: "/users/token"))
                tokenRequest.httpMethod = HTTPMethod.post.rawValue
                tokenRequest.httpBody = "username=\(username)&password=\(password)&grant_type=password"
                    .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)?
                    .data(using: .utf8)
                tokenRequest.addValue(HTTPContentType.encodedForm.rawValue, forHTTPHeaderField: "Content-Type")
                lastUserToken = LastIamagesUserToken(
                    token: try self.jsond.decode(
                        IamagesUserToken.self,
                        from: try await URLSession.shared.data(for: tokenRequest).0
                    ),
                    date: .now
                )
                try self.keychain.setDataWithKey(self.jsone.encode(lastUserToken), key: .lastUserToken)
            }
        }
        if let lastUserToken {
            uploadRequest.addValue("\(lastUserToken.token.tokenType) \(lastUserToken.token.accessToken)", forHTTPHeaderField: "Authorization")
        }
        
        guard let file else {
            throw NoImageDataError()
        }
        let mimeType = file.type.components(separatedBy: "/")
        
        let form: MultipartFormData = try MultipartFormData(
            boundary: try Boundary(uncheckedBoundary: "iamages")
        ) {
            try Subpart {
                ContentDisposition(name: "information")
                ContentType(mediaType: .applicationJson)
            } body: {
                try self.jsone.encode(information)
            }
            
            Subpart {
                ContentDisposition(name: "file", filename: "image.bin")
                ContentType(mediaType: MediaType(type: mimeType[0], subtype: mimeType[1]))
            } body: {
                file.data
            }
        }
        uploadRequest.httpBody = form.httpBody
        
        let (data, response) = try await URLSession.shared.data(for: uploadRequest, delegate: self)
        guard let response = response as? HTTPURLResponse else {
            throw APICommunicationErrors.invalidResponse(uploadRequest.url)
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
    }
}
