import SwiftUI

final class SplitViewModel: ObservableObject {
    // MARK: Images
    @Published var selectedImage: IamagesImage?
    @Published var selectedImageMetadata: IamagesImageMetadataContainer?
}
