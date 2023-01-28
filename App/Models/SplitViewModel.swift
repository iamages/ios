import SwiftUI

final class SplitViewModel: ObservableObject {
    @Published var selectedView: AppUserViews = .images
    @Published var selectedImage: String?
    @Published var images: [IamagesImageAndMetadataContainer] = []
    @Published var imageToDelete: IamagesImageAndMetadataContainer?
}
