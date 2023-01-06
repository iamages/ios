import SwiftUI

struct AddToCollectionView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    @Environment(\.dismiss) private var dismiss
    
    let collectionID: String
    let imageID: String
    
    @State private var isBusy: Bool = true
    @State private var error: Error?
    
    private func addToCollection() async {
        self.isBusy = true
        do {
            try await self.globalViewModel.fetchData(
                "/collections/\(self.collectionID)",
                method: .patch,
                body: self.globalViewModel.jsone.encode(
                    IamagesCollectionEdit(
                        change: .addImages,
                        to: .stringArray([self.imageID])
                    )
                ),
                contentType: .json,
                authStrategy: .required
            )
            self.dismiss()
        } catch {
            self.isBusy = false
            self.error = error
        }
    }
    
    var body: some View {
        if let error {
            IconAndInformationView(
                icon: "xmark.octagon.fill",
                heading: "Could not add image to collection",
                subheading: error.localizedDescription,
                additionalViews: AnyView(
                    Button("Retry") {
                        self.error = nil
                    }
                )
            )
        } else {
            ProgressView("Adding image to collection...")
                .task {
                    await self.addToCollection()
                }
        }
    }
}

#if DEBUG
struct AddToCollectionView_Previews: PreviewProvider {
    static var previews: some View {
        AddToCollectionView(
            collectionID: "test", imageID: "test"
        )
        .environmentObject(GlobalViewModel())
    }
}
#endif
