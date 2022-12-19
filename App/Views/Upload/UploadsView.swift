import SwiftUI
import PhotosUI

struct UploadsView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    #if !targetEnvironment(macCatalyst)
    @Binding var isPresented: Bool
    #endif
    
    @State private var selectedUploadContainer: IamagesUploadContainer?
    @State private var uploadContainers: [IamagesUploadContainer] = []
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
                            self.isPresented = false
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
                            Label("Upload into collection", systemImage: "square.grid.3x1.folder.badge.plus")
                        }
                    } label: {
                        Label("Upload", systemImage: "square.and.arrow.up.on.square")
                    }
                    .disabled(self.uploadContainers.isEmpty || self.isBusy)
                }
            }
        } detail: {
            #if targetEnvironment(macCatalyst)
            UploadEditorView(
                selectedUploadContainer: self.$selectedUploadContainer
            )
            #else
            UploadEditorView(
                isPresented: self.$isPresented,
                selectedUploadContainer: self.$selectedUploadContainer
            )
            #endif
        }
        .navigationTitle("Uploads")
        .fullScreenCover(isPresented: self.$isUploadingCoverPresented) {
            UploadingView(
                isPresented: self.$isUploadingCoverPresented,
                uploadContainers: self.$uploadContainers
            )
        }
        .sheet(isPresented: self.$isImportErrorsSheetPresented) {
            UploadImportErrorsView(
                errors: self.$fileImportErrors,
                isPresented: self.$isImportErrorsSheetPresented
            )
        }
        .sheet(isPresented: self.$isNewCollectionSheetPresented, onDismiss: {
            self.isUploadingCoverPresented = true
        }) {
            EmptyView()
        }
    }
}

#if DEBUG
struct UploadsView_Previews: PreviewProvider {
    static var previews: some View {
        #if targetEnvironment(macCatalyst)
        UploadsView()
            .environmentObject(GlobalViewModel())
        #else
        UploadsView(isPresented: .constant(true))
            .environmentObject(GlobalViewModel())
        #endif
    }
}
#endif
