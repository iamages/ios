import Foundation

final class SplitViewModel: ObservableObject {
    // MARK: Selected image
    @Published var selectedImage: IamagesImage?
    @Published var selectedImageMetadata: IamagesImageMetadata?
    var selectedImageTitle: String {
        if let image = self.selectedImage {
            if let metadata = self.selectedImageMetadata {
                return metadata.description
            } else {
                if image.lock.isLocked {
                    return NSLocalizedString("Locked image", comment: "")
                } else {
                    return NSLocalizedString("Loading metadata...", comment: "")
                }
                
            }
        }
        return ""
    }

    // MARK: Selected collection
    @Published var selectedCollection: IamagesCollection?
    @Published var selectedCollectionMetadata: IamagesCollectionMetadata?
}
