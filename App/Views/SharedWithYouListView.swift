import SwiftUI
import SharedWithYou

struct SharedWithYouListView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    @EnvironmentObject private var splitViewModel: SplitViewModel
    
    @StateObject private var swViewModel = SWViewModel()
    
    @State private var collections: [IamagesCollection] = []
    
    @ViewBuilder
    private var list: some View {
        List {
            Section("Images") {
                ForEach(self.$splitViewModel.images) { imageAndMetadata in
                    NavigableImageView(imageAndMetadata: imageAndMetadata)
                }
            }
            Section("Collections") {
                ForEach(self.collections) { collection in
                    NavigableCollectionView(collection: collection)
                }
            }
        }
        .navigationDestination(for: IamagesCollection.ID.self) { id in
            if let i = self.collections.firstIndex(where: { $0.id == id }),
               let collection = self.$collections[i]
            {
                CollectionImagesListView(collection: collection)
                    .environmentObject(self.splitViewModel)
            } else {
                Text("Cannot open collection")
            }
        }
        .task {
            for highlight in self.swViewModel.highlightCenter.highlights {
                
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .newSWHighlights)) { output in
            guard let highlights = output.object as? [SWHighlight] else {
                return
            }
        }
    }
    
    var body: some View {
        Group {
            if self.swViewModel.highlightCenter.highlights.isEmpty {
                IconAndInformationView(
                    icon: "shared.with.you",
                    heading: "Nothing Shared with You",
                    subheading: "Iamages embed links sent to you via Messages will appear here."
                )
            } else {
                self.list
            }
        }
        .navigationTitle("Shared with You")
    }
}

struct SharedWithYouListView_Previews: PreviewProvider {
    static var previews: some View {
        SharedWithYouListView()
            .environmentObject(SplitViewModel())
    }
}
