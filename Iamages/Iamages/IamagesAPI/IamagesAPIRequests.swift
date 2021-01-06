import Foundation
import UIKit

struct IamagesUserModifyRequest: Equatable {
    var modifications: [IamagesUserModifiable: String]
}

struct IamagesFileModifyRequest: Equatable {
    var id: Int
    var modifications: [IamagesFileModifiable: AnyHashable]
}

struct IamagesUploadRequest: Identifiable, Equatable, Hashable {
    let id: UUID = UUID()
    var description: String
    var isNSFW: Bool
    var isPrivate: Bool
    var img: UIImage
}

