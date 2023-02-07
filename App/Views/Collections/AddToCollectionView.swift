import SwiftUI

struct AddToCollectionView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    
    let collectionID: String
    let imageID: String
    // Pops the sheet instead of navigating back to collections list.
    let rootDismissFunction: () -> Void
    
    @State private var isBusy = true
    @State private var error: Error?
    @State private var isAddedToCollection = false
    
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
            self.isAddedToCollection = true
        } catch {
            self.isBusy = false
            self.error = error
        }
    }
    
    var body: some View {
        if self.isAddedToCollection {
            IconAndInformationView(
                icon: "checkmark",
                heading: "Added to collection"
            )
            .navigationBarBackButtonHidden()
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now().advanced(by: .seconds(1))) {
                    self.rootDismissFunction()
                }
            }
        } else if let error {
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
                .navigationBarBackButtonHidden()
                .interactiveDismissDisabled()
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
            collectionID: "test", imageID: "test",
            rootDismissFunction: {}
        )
        .environmentObject(GlobalViewModel())
    }
}
#endif
