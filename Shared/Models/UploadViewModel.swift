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
    var collectionID: String?
    
    init(
        viewContext: NSManagedObjectContext? = nil,
        collectionID: String? = nil
    ) {
        self.jsond.dateDecodingStrategy = .iso8601
        self.jsone.dateEncodingStrategy = .iso8601
        self.viewContext = viewContext
        self.collectionID = collectionID
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
    
    private func checkResponseStatus(for response: URLResponse, body: Data) throws {
        guard let response = response as? HTTPURLResponse else {
            throw APICommunicationErrors.invalidResponse(response.url)
        }
        if response.statusCode < 200 || response.statusCode > 299 {
            let detail: String
            do {
                detail = try self.jsond.decode(APIErrorDetails.self, from: body).detail
            } catch {
                detail = String(decoding: body, as: UTF8.self)
            }
            throw APICommunicationErrors.badResponse(response.statusCode, detail)
        }
    }
    
    private func setAuthorizationHeader(for request: inout URLRequest) async throws {
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
            request.addValue("\(lastUserToken.token.tokenType) \(lastUserToken.token.accessToken)", forHTTPHeaderField: "Authorization")
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
        
        do {
            var uploadRequest = URLRequest(url: .apiRootUrl.appending(path: "/images", directoryHint: .isDirectory))
            try await self.setAuthorizationHeader(for: &uploadRequest)
            uploadRequest.httpMethod = HTTPMethod.post.rawValue
            uploadRequest.addValue(HTTPContentType.multipart.rawValue, forHTTPHeaderField: "Content-Type")

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
            try self.checkResponseStatus(for: response, body: data)
            self.uploadedImage = try self.jsond.decode(IamagesImage.self, from: data)
            if uploadRequest.value(forHTTPHeaderField: "Authorization") == nil,
               let viewContext,
               let uploadedImage,
               let ownerlessKeyString = (response as? HTTPURLResponse)?.value(forHTTPHeaderField: "X-Iamages-Ownerless-Key"),
               let ownerlessKey = UUID(uuidString: ownerlessKeyString)
            {
                let anonymousUpload = AnonymousUpload(context: viewContext)
                anonymousUpload.id = uploadedImage.id
                anonymousUpload.ownerlessKey = ownerlessKey
                try await viewContext.perform {
                    try viewContext.save()
                }
            }
            if let collectionID,
               let uploadedImage
            {
                var patchCollectionRequest = URLRequest(url: .apiRootUrl.appending(path: "/collections/\(collectionID)"))
                try await self.setAuthorizationHeader(for: &patchCollectionRequest)
                patchCollectionRequest.httpMethod = "PATCH"
                patchCollectionRequest.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
                patchCollectionRequest.httpBody = try self.jsone.encode(
                    IamagesCollectionEdit(
                        change: .addImages,
                        to: .stringArray([uploadedImage.id])
                    )
                )
                let (data, response) = try await URLSession.shared.data(for: patchCollectionRequest)
                try self.checkResponseStatus(for: response, body: data)
            }
        } catch {
            self.error = LocalizedAlertError(error: error)
        }

        self.isUploading = false
    }
}
