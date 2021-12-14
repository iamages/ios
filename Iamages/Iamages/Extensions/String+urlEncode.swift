import Foundation

extension String {
    func urlEncode() -> String {
        return self.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!
    }
}
