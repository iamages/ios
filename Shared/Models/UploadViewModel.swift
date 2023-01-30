import SwiftUI
import CoreData
import KeychainAccess
import MultipartFormData

struct IamagesUploadInformation: Codable, Hashable {
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

struct IamagesUploadContainer: Identifiable {
    let id: UUID = UUID()
    var information: IamagesUploadInformation = IamagesUploadInformation()
    var file: IamagesUploadFile
    
    func validate() throws {
        if self.information.description.isEmpty || self.information.description.count > 255 {
            throw FieldRequirementError.imageDescription
        }
        if self.information.isLocked && self.information.lockKey.isEmpty {
            throw FieldRequirementError.missingLockKey
        }
        if self.file.data.count > 30000000 {
            throw FieldRequirementError.imageToLarge
        }
    }
}

enum UploadContainerValidationError: Error {
    case withContainer(String, LocalizedError)
}

extension UploadContainerValidationError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .withContainer(let description, let error):
            return "\(error.localizedDescription) for '\(description.isEmpty ? "No description yet" : description)'"
        }
    }
    var recoverySuggestion: String? {
        switch self {
        case .withContainer(_, let error):
            return error.recoverySuggestion
        }
    }
}

struct NoImageDataError: LocalizedError {
    let errorDescription: String? = NSLocalizedString("Could not load image data.", comment: "")
    let recoverySuggestion: String? = NSLocalizedString("Make sure your image is a JPEG, PNG, GIF or WebP file.", comment: "")
}

@MainActor
final class UploadViewModel: NSObject, ObservableObject, URLSessionTaskDelegate {
    private let keychain = Keychain.getIamagesKeychain()
    private let jsond = JSONDecoder()
    private let jsone = JSONEncoder()
    
    @Published var information: IamagesUploadInformation = IamagesUploadInformation()
    @Published var file: IamagesUploadFile?
    
    @Published var isUploading: Bool = false
    @Published var progress: Double = 0.0
    @Published var uploadedImage: IamagesImage?
    @Published var error: LocalizedAlertError?
    
    var viewContext: NSManagedObjectContext?
    
    init(viewContext: NSManagedObjectContext? = nil) {
        self.jsond.dateDecodingStrategy = .iso8601
        self.jsone.dateEncodingStrategy = .iso8601
        self.viewContext = viewContext
        super.init()
    }
    
    nonisolated internal func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
    ) {
        DispatchQueue.main.async {
            self.progress = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
        }
    }
    
    func checkLoggedIn() -> Bool {
        do {
            return try self.keychain.getStringWithKey(.username) != nil
        } catch {
            print(error)
            return false
        }
    }
    
    func upload() async {
        // Reset progress
        self.isUploading = true
        self.error = nil
        self.progress = 0.0
        
        // Validate upload
        do {
            guard let file else {
                throw NoImageDataError()
            }
            try IamagesUploadContainer(information: self.information, file: file).validate()
        } catch {
            self.error = LocalizedAlertError(error: error)
            self.isUploading = false
            return
        }

        var uploadRequest = URLRequest(url: .apiRootUrl.appending(path: "/images", directoryHint: .isDirectory))
        uploadRequest.httpMethod = HTTPMethod.post.rawValue
        uploadRequest.addValue(HTTPContentType.multipart.rawValue, forHTTPHeaderField: "Content-Type")
        
        do {
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

            let mimeType = self.file!.type.components(separatedBy: "/")
            
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
                    self.file!.data
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
            self.uploadedImage = try self.jsond.decode(IamagesImage.self, from: data)
            if lastUserToken == nil,
               let viewContext,
               let uploadedImage,
               let ownerlessKeyString = response.value(forHTTPHeaderField: "X-Iamages-Ownerless-Key"),
               let ownerlessKey = UUID(uuidString: ownerlessKeyString)
            {
                let anonymousUpload = AnonymousUpload(context: viewContext)
                anonymousUpload.id = uploadedImage.id
                anonymousUpload.ownerlessKey = ownerlessKey
                try await viewContext.perform {
                    try viewContext.save()
                }
            }
        } catch {
            self.error = LocalizedAlertError(error: error)
        }

        self.isUploading = false
    }
}
