#if !targetEnvironment(macCatalyst)
import SwiftUI

struct NewMenuModifier: ViewModifier {
    @ObservedObject var globalViewModel: GlobalViewModel
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: self.$globalViewModel.isNewCollectionPresented) {
                NewCollectionView()
            }
            .fullScreenCover(isPresented: self.$globalViewModel.isUploadsPresented) {
                UploadsView()
            }
            .toolbar {
                ToolbarItem {
                    Menu {
                        Button(action: {
                            self.globalViewModel.isUploadsPresented = true
                        }) {
                            Label("Uploads", systemImage: "arrow.up.doc")
                        }
                        .disabled(self.globalViewModel.isNewCollectionPresented)
                        NewCollectionButton()
                    } label: {
                        Label("New", systemImage: "plus")
                    }
                }
            }
    }
}
#endif
