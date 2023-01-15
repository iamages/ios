import SwiftUI
import OrderedCollections

final class SplitViewModel: ObservableObject {
    @Published var selectedImage: String?
    @Published var images: OrderedDictionary<String, IamagesImageAndMetadataContainer> = [:]
}
