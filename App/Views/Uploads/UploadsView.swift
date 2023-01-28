import SwiftUI

struct UploadsView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel

    #if !targetEnvironment(macCatalyst)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dismiss) private var dismiss
    #endif
    
    @StateObject private var uploadsViewModel = UploadsViewModel()
    
    // TODO: Collection information
    @State private var isNewCollectionSheetPresented: Bool = false
    @State private var isUploadingCoverPresented: Bool = false
    
    var body: some View {
        NavigationSplitView {
            UploadContainersListView()
                .environmentObject(self.uploadsViewModel)
                .toolbar {
                    #if !targetEnvironment(macCatalyst)
                    ToolbarItem(placement: .navigationBarLeading) {
                        if self.horizontalSizeClass == .compact {
                            Button(action: {
                                self.dismiss()
                            }) {
                                Label("Close", systemImage: "xmark")
                            }
                            .keyboardShortcut("w")
                        }
                    }
                    #endif
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Button(action: {
                                self.isUploadingCoverPresented = true
                                self.uploadsViewModel.selectedUploadContainer = nil
                            }) {
                                Label("Upload separately", systemImage: "square.and.arrow.up.on.square")
                            }
                            Button(action: {
                                self.isNewCollectionSheetPresented = true
                                self.uploadsViewModel.selectedUploadContainer = nil
                            }) {
                                Label(
                                    self.globalViewModel.isLoggedIn ? "Upload into collection" : "Log in to upload into collection",
                                    systemImage: "square.grid.3x1.folder.badge.plus"
                                )
                            }
                            .disabled(!self.globalViewModel.isLoggedIn)
                        } label: {
                            Label("Upload", systemImage: "square.and.arrow.up.on.square")
                        }
                        .disabled(self.uploadsViewModel.uploadContainers.isEmpty || self.uploadsViewModel.isBusy)
                    }
                }
        } detail: {
            Group {
                if let id = self.uploadsViewModel.selectedUploadContainer,
                   let i = self.uploadsViewModel.uploadContainers.firstIndex(where: { $0.id == id }),
                   let uploadContainer = self.$uploadsViewModel.uploadContainers[i]
                {
                    UploadEditorView(
                        uploadContainer: uploadContainer
                    )
                    .environmentObject(self.uploadsViewModel)
                } else {
                    Text("Select an upload to edit")
                        .navigationTitle("")
                }
            }
            .toolbar {
                #if !targetEnvironment(macCatalyst)
                ToolbarItem(placement: .primaryAction) {
                    if self.horizontalSizeClass == .regular {
                        Button(action: {
                            self.dismiss()
                        }) {
                            Label("Close", systemImage: "xmark")
                        }
                        .keyboardShortcut("w")
                    }
                }
                #endif
            }
        }
        .navigationTitle("Uploads")
        #if targetEnvironment(macCatalyst)
        .navigationSubtitle("\(self.uploadsViewModel.uploadContainers.count) image\(self.uploadsViewModel.uploadContainers.count > 1 || self.uploadsViewModel.uploadContainers.isEmpty ? "s" : "")")
        #endif
        .fullScreenCover(isPresented: self.$isUploadingCoverPresented) {
            UploadingView()
                .environmentObject(self.uploadsViewModel)
        }
        .sheet(isPresented: self.$isNewCollectionSheetPresented, onDismiss: {
            self.isUploadingCoverPresented = true
        }) {
            NewCollectionView()
        }
    }
}

#if DEBUG
struct UploadsView_Previews: PreviewProvider {
    static var previews: some View {
        UploadsView()
            .environmentObject(GlobalViewModel())
    }
}
#endif
