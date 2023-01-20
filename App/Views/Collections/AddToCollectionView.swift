import SwiftUI

struct AddToCollectionView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    @Environment(\.dismiss) private var dismiss
    
    let collectionID: String
    let imageID: String
    @Binding var isAddedToCollection: Bool
    
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
                    self.dismiss()
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
            isAddedToCollection: .constant(false)
        )
        .environmentObject(GlobalViewModel())
    }
}
#endif
