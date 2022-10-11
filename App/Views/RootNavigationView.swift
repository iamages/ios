import SwiftUI

struct RootNavigationView: View {
    @EnvironmentObject var viewModel: ViewModel
    @Environment(\.openWindow) var openWindow
    
    #if !os(macOS)
    @State private var isSettingsSheetPresented: Bool = false
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
                            #if os(macOS)
                            self.openWindow(id: "upload")
                            #else
                            self.viewModel.isUploadDetailVisible = true
                            #endif
                        }) {
                            Label("Upload", systemImage: "plus")
                        }
                        #if os(iOS)
                        .disabled(self.viewModel.isUploadDetailVisible)
                        #endif
                    }
                }
        } detail: {
            if self.viewModel.isUploadDetailVisible {
                UploadView()
            } else {
                if let selectedImage: IamagesImage = self.viewModel.selectedImage {
                    ImageDetailView(image: selectedImage)
                } else {
                    Text("Select something on the sidebar")
                        .navigationTitle("") // BUGFIX: UploadView's title sticks even though view is gone.
                }
            }
        }
        #if !os(macOS)
        .sheet(isPresented: self.$isSettingsSheetPresented) {
            SettingsView(isPresented: self.$isSettingsSheetPresented)
        }
        #endif
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
