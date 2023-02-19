import Foundation

enum BoolOrStringError: LocalizedError {
    enum BoolOrStringWithoutParameters: String {
        case bool = "Bool"
        case string = "String"
        case stringArray = "[String]"
    }
    
    case wrongType(String, BoolOrStringWithoutParameters)
}

extension BoolOrStringError {
    public var errorDescription: String? {
        switch self {
        case .wrongType(let field, let type):
            return NSLocalizedString("Expected data type \(type) for '\(field)'.", comment: "")
        }
    }
}

enum BoolOrString: Codable {
    case bool(Bool)
    case string(String)
    case stringArray([String])
}
