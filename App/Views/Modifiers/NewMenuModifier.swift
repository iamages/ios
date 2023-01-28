#if !targetEnvironment(macCatalyst)
import SwiftUI

struct NewMenuModifier: ViewModifier {
    @ObservedObject var globalViewModel: GlobalViewModel
    
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem {
                    Menu {
                        Button(action: {
                            self.globalViewModel.isUploadsPresented = true
                        }) {
                            Label("Uploads", systemImage: "arrow.up.doc")
                        }
                        .disabled(self.globalViewModel.isNewCollectionPresented)
                        Button(action: {
                            self.globalViewModel.isNewCollectionPresented = true
                        }) {
                            Label(self.globalViewModel.isLoggedIn ? "Collection" : "Log in to upload into collection", systemImage: "folder.badge.plus")
                        }
                        .disabled(!self.globalViewModel.isLoggedIn || self.globalViewModel.isUploadsPresented)
                    } label: {
                        Label("New", systemImage: "plus")
                    }
                }
            }
    }
}
#endif
