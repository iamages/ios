import SwiftUI

struct NewCollectionButton: View {
    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    
    var body: some View {
        Button(action: {
            #if targetEnvironment(macCatalyst)
            openWindow(id: "newCollection")
            #else
            self.globalViewModel.isNewCollectionPresented = true
            #endif
        }) {
            Label(self.globalViewModel.isLoggedIn ? "Collection" : "Log in to use collections", systemImage: "folder.badge.plus")
        }
        #if targetEnvironment(macCatalyst)
        .disabled(!self.globalViewModel.isLoggedIn)
        #else
        .disabled(!self.globalViewModel.isLoggedIn || self.globalViewModel.isUploadsPresented)
        #endif
    }
}

#if DEBUG
struct NewCollectionButton_Previews: PreviewProvider {
    static var previews: some View {
        NewCollectionButton()
            .environmentObject(GlobalViewModel())
    }
}
#endif
