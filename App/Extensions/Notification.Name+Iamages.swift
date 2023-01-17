import Foundation

extension Notification.Name {
    static let editImage: Self = .init("editImage")
    static let deleteImage: Self = .init("deleteImage")
    static let editCollection: Self = .init("editCollection")
    static let uploadComplete: Self = .init("uploadComplete")
    static let deleteUpload: Self = .init("deleteUpload")
}
