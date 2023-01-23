import Foundation

extension URL {
    #if DEBUG
    static let apiRootUrl = URL(string: "http://localhost:9999/api")!
    #else
    static let apiRootUrl = URL(string: "https://api.iamages.jkelol111.me/v4")!
    #endif
}
