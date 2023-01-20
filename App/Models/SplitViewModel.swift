import SwiftUI

final class SplitViewModel: ObservableObject {
    @Published var selectedImage: String?
    @Published var images: [IamagesImageAndMetadataContainer] = []
    @Published var isDetailViewVisible: Bool = false
}
