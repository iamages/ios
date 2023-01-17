import SwiftUI
import OrderedCollections

struct UploadsView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel

    #if !targetEnvironment(macCatalyst)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dismiss) private var dismiss
    #endif
    
    @State private var selectedUploadContainer: UUID?
    @State private var uploadContainers: OrderedDictionary<UUID, IamagesUploadContainer> = [:]
    @State private var isBusy: Bool = false

    @State private var fileImportErrors: [IdentifiableLocalizedError] = []
    @State private var isImportErrorsSheetPresented: Bool = false
    
    // TODO: Collection information
    @State private var isNewCollectionSheetPresented: Bool = false
    @State private var isUploadingCoverPresented: Bool = false
    
    var body: some View {
        NavigationSplitView {
            UploadContainersListView(
                selectedUploadContainer: self.$selectedUploadContainer,
                uploadContainers: self.$uploadContainers,
                fileImportErrors: self.$fileImportErrors,
                isBusy: self.$isBusy
            )
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
                ToolbarItem {
                    if !self.fileImportErrors.isEmpty {
                        Button(action: {
                            self.isImportErrorsSheetPresented = true
                        }) {
                            Label("Import errors", systemImage: "exclamationmark.octagon")
                        }
                        .badge(self.fileImportErrors.count)
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: {
                            self.isUploadingCoverPresented = true
                            self.selectedUploadContainer = nil
                        }) {
                            Label("Upload separately", systemImage: "square.and.arrow.up.on.square")
                        }
                        Button(action: {
                            self.isNewCollectionSheetPresented = true
                            self.selectedUploadContainer = nil
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
                    .disabled(self.uploadContainers.isEmpty || self.isBusy)
                }
            }
        } detail: {
            Group {
                if let id = self.selectedUploadContainer,
                   var uploadContainer = Binding<IamagesUploadContainer>(self.$uploadContainers[id]) {
                    UploadEditorView(
                        id: id,
                        information: uploadContainer.information
                    )
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
        .fullScreenCover(isPresented: self.$isUploadingCoverPresented) {
            UploadingView(
                uploadContainers: self.$uploadContainers
            )
        }
        .sheet(isPresented: self.$isImportErrorsSheetPresented) {
            UploadImportErrorsView(
                errors: self.$fileImportErrors
            )
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
