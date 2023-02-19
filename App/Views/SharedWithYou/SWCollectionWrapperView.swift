import SwiftUI
import SharedWithYou

struct SWCollectionWrapperView: View {
    let collection: IamagesCollection
    @ObservedObject var swViewModel: SWViewModel
    
    @State private var highlight: SWHighlight?
    @State private var error: Error?

    var body: some View {
        VStack {
            NavigableCollectionView(collection: self.collection)
            if let highlight {
                SWAttributionViewSwiftUI(highlight: highlight)
            } else if let error {
                Text(error.localizedDescription)
                    .lineLimit(1)
                    .background {
                        Capsule()
                            .fill(.gray)
                    }
            } else {
                ProgressView()
                    .task {
                        do {
                            self.highlight = try await self.swViewModel.highlightCenter.highlight(for: .apiRootUrl.appending(path: "/collections/\(self.collection.id)/embed"))
                        } catch {
                            self.error = error
                        }
                    }
            }
        }
    }
}

#if DEBUG
struct SWCollectionWrapperView_Previews: PreviewProvider {
    static var previews: some View {
        SWCollectionWrapperView(
            collection: previewCollection,
            swViewModel: SWViewModel()
        )
    }
}
#endif
