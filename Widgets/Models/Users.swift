import Foundation
import KeychainAccess

class UserManager: NSObject, URLSessionTaskDelegate {
    struct NotLoggedInError: LocalizedError {
        var errorDescription: String? = "Log in the Iamages app"
    }

    private let keychain = Keychain.getIamagesKeychain()
    private let jsone = JSONEncoder()
    private let jsond = JSONDecoder()

    var session: URLSession = URLSession.shared
    
    override init() {
        super.init()
        self.jsone.dateEncodingStrategy = .iso8601
        self.jsond.dateDecodingStrategy = .iso8601
        self.session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
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
                try await self.getUserToken(for: &newRequest)
            } catch {
                print(error)
            }
        }
        return newRequest
    }
    
    func getUserToken(for request: inout URLRequest) async throws {
        guard let tokenData = try self.keychain.getDataWithKey(.lastUserToken) else {
            throw NotLoggedInError()
        }
        var lastUserToken = try self.jsond.decode(LastIamagesUserToken.self, from: tokenData)
        if Date.now.timeIntervalSince(lastUserToken.date) > 1800 {
            guard let username = try self.keychain.getStringWithKey(.username),
                  let password = try self.keychain.getStringWithKey(.password) else {
                throw NotLoggedInError()
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
        request.addValue("\(lastUserToken.token.tokenType) \(lastUserToken.token.accessToken)", forHTTPHeaderField: "Authorization")
    }
}
