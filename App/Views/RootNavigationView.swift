import SwiftUI

struct RootNavigationView: View {
    @EnvironmentObject var viewModel: ViewModel
    @Environment(\.openWindow) var openWindow

    #if !os(macOS)
    @State private var isSettingsSheetPresented: Bool = false
    @State private var isUploadsCoverPresented: Bool = false
    #endif
    
    var body: some View {
        NavigationSplitView {
            ImagesGridView()
                .toolbar {
                    #if !os(macOS)
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            self.isSettingsSheetPresented = true
                        }) {
                            Label("Settings", systemImage: "gear")
                        }
                    }
                    #endif
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: {
                            NotificationCenter.default.post(name: Notification.Name("openUploads"), object: nil)
                        }) {
                            Label("Upload", systemImage: "plus")
                        }
                    }
                }
        } detail: {
            if let selectedImage: IamagesImage = self.viewModel.selectedImage {
                ImageDetailView(image: selectedImage)
            } else {
                Text("Select something on the sidebar")
            }
        }
        #if os(iOS)
        .sheet(isPresented: self.$isSettingsSheetPresented) {
            SettingsView(isPresented: self.$isSettingsSheetPresented)
        }
        .fullScreenCover(isPresented: self.$isUploadsCoverPresented) {
            UploadView(isPresented: self.$isUploadsCoverPresented)
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("openSettings"))) { _ in
            self.isSettingsSheetPresented = true
        }
        #endif
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("openUploads"))) { _ in
            #if os(macOS)
            openWindow(id: "uploads")
            #else
            self.isUploadsCoverPresented = true
            #endif
        }
    }
}

#if DEBUG
struct RootNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        RootNavigationView()
            .environmentObject(ViewModel())
    }
}
#endif
