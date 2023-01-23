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
                            Label("Collection", systemImage: "folder.badge.plus")
                        }
                        .disabled(!self.globalViewModel.isLoggedIn || self.globalViewModel.isUploadsPresented)
                    } label: {
                        Label("New", systemImage: "plus")
                    }
                }
            }
    }
}

extension View {
    func newMenuToolbarItem(globalViewModel: GlobalViewModel) -> some View {
        modifier(NewMenuModifier(globalViewModel: globalViewModel))
    }
}
#endif
