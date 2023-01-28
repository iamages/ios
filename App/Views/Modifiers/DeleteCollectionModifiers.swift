import SwiftUI

struct DeleteCollectionListenerModifier: ViewModifier {
    @Binding var collections: [IamagesCollection]
    @Binding var navigationPath: [String]
    
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .deleteCollection)) { output in
                guard let id = output.object as? String,
                      let i = self.collections.firstIndex(where: { $0.id == id })
                else {
                    return
                }
                if self.navigationPath.last == id {
                    self.navigationPath.removeLast()
                }
                withAnimation {
                    self.collections.remove(at: i)
                }
            }
    }
}

struct DeleteCollectionAlertModifier: ViewModifier {
    @Binding var collectionToDelete: IamagesCollection?
    @ObservedObject var globalViewModel: GlobalViewModel
    
    @State private var error: LocalizedAlertError?

    func body(content: Content) -> some View {
        content
            .errorAlert(error: self.$error)
            .alert(
                "Delete collection?",
                isPresented: .constant(self.collectionToDelete != nil),
                presenting: self.collectionToDelete
            ) { collection in
                Button("Delete", role: .destructive) {
                    Task {
                        do {
                            try await self.globalViewModel.fetchData(
                                "/collections/\(collection.id)",
                                method: .delete,
                                authStrategy: .required
                            )
                            NotificationCenter.default.post(
                                name: .deleteCollection,
                                object: collection.id
                            )
                        } catch {
                            self.error = LocalizedAlertError(error: error)
                        }
                    }
                    self.collectionToDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    self.collectionToDelete = nil
                }
            } message: { collection in
                Text("'\(collection.description)' will be deleted!\nThe images it contains will not be deleted.")
            }
    }
}
