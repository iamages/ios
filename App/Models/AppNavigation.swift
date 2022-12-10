import Foundation

enum AppUserViews: Identifiable, CaseIterable {
    var id: Self { self }
    
    case images
    case collections
    
    var localizedName: String {
        switch self {
        case .images:
            return NSLocalizedString("Images", comment: "")
        case .collections:
            return NSLocalizedString("Collections", comment: "")
        }
    }
    
    var icon: String {
        switch self {
        case .images:
            return "photo.stack"
        case .collections:
            return "folder"
        }
    }
}

enum AppSettingsViews: Identifiable, CaseIterable, Codable {
    var id: Self { self }
    
    case account
    case uploads
    case tips
    case maintainance
    case about
    
    var localizedName: String {
        switch self {
        case .account:
            return NSLocalizedString("Account", comment: "")
        case .uploads:
            return NSLocalizedString("Uploads", comment: "")
        case .tips:
            return NSLocalizedString("Tip Jar", comment: "")
        case .maintainance:
            return NSLocalizedString("Maintainance", comment: "")
        case .about:
            return NSLocalizedString("About", comment: "")
        }
    }
    
    var icon: String {
        switch self {
        case .account:
            return "person"
        case .uploads:
            return "square.and.arrow.up.on.square"
        case .tips:
            return "cup.and.saucer"
        case .maintainance:
            return "wrench"
        case .about:
            return "info.square"
        }
    }
}
