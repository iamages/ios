import SwiftUI
import PhotosUI

struct UploadContainersListView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    @EnvironmentObject private var uploadsViewModel: UploadsViewModel
    @Environment(\.editMode) private var editMode
    
    @AppStorage("uploadDefaults.isPrivate", store: .iamagesGroup)
    private var isPrivateDefault: Bool = false
    
    @AppStorage("uploadDefaults.isLocked", store: .iamagesGroup)
    private var isLockedDefault: Bool = false

    @State private var error: LocalizedAlertError?
    @State private var isFilePickerPresented: Bool = false
    @State private var photoPickerItems: [PhotosPickerItem] = []
    
    private func handleImagesPicked() async {
        self.uploadsViewModel.isBusy = true
        
        for image in self.photoPickerItems {
            do {
                guard let data = try await image.loadTransferable(type: Data.self) else {
                    throw FileImportErrors.loadPhotoFromLibraryFailure
                }
                if data.count > self.globalViewModel.maxImageSize {
                    throw FileImportErrors.tooLarge(image.itemIdentifier ?? "Unknown", data.count)
                }
                
                guard let type: UTType = image.supportedContentTypes.first,
                      let mime: String = type.preferredMIMEType else {
                    throw FileImportErrors.noType("Photo library file")
                }
                
                if !self.globalViewModel.acceptedFileTypes.contains(mime) {
                    throw FileImportErrors.unsupportedType("Photo library file", mime)
                }
                
                var container = IamagesUploadContainer(
                    file: IamagesUploadFile(
                        data: data,
                        type: mime
                    )
                )
                container.information.isPrivate = self.isPrivateDefault
                container.information.isLocked = self.isLockedDefault
                
                self.uploadsViewModel.uploadContainers.append(container)
            } catch {
                self.error = LocalizedAlertError(error: error)
            }
        }
        self.photoPickerItems = []
        
        self.uploadsViewModel.isBusy = false
    }
    
    private func handleFilePicked(_ result: Result<[URL], Error>) {
        self.uploadsViewModel.isBusy = true

        switch result {
        case .success(let urls):
            for url in urls {
                do {
                    let meta = try url.resourceValues(forKeys: [.fileSizeKey, .contentTypeKey])

                    guard let size: Int = meta.fileSize else {
                        throw FileImportErrors.noSize(url.lastPathComponent)
                    }
                    if size > self.globalViewModel.maxImageSize {
                        throw FileImportErrors.tooLarge(url.lastPathComponent, size)
                    }

                    guard let type: String = meta.contentType?.preferredMIMEType else {
                        throw FileImportErrors.noType(url.lastPathComponent)
                    }
                    if !self.globalViewModel.acceptedFileTypes.contains(type) {
                        throw FileImportErrors.unsupportedType(url.lastPathComponent, type)
                    }
                    
                    var container = IamagesUploadContainer(
                        file: IamagesUploadFile(
                            data: try Data(contentsOf: url),
                            type: type
                        )
                    )
                    container.information.isPrivate = self.isPrivateDefault
                    container.information.isLocked = self.isLockedDefault

                    self.uploadsViewModel.uploadContainers.append(container)
                } catch {
                    self.error = LocalizedAlertError(error: error)
                }
            }
        case .failure(let error):
            self.error = LocalizedAlertError(error: error)
        }
        
        self.uploadsViewModel.isBusy = false
    }

    var body: some View {
        Group {
            if self.uploadsViewModel.uploadContainers.isEmpty {
                IconAndInformationView(
                    icon: "questionmark.folder",
                    heading: "No images added"
                )
            } else {
                List(selection: self.$uploadsViewModel.selectedUploadContainer) {
                    ForEach(self.uploadsViewModel.uploadContainers) { uploadContainer in
                        NavigableUploadContainerView(
                            uploadContainer: uploadContainer
                        )
                        .contextMenu {
                            Button(role: .destructive, action: {
                                self.uploadsViewModel.deleteUpload(id: uploadContainer.id)
                            }) {
                                Label("Delete upload", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Uploads")
        .navigationBarTitleDisplayMode(.inline)
        .errorToast(error: self.$error)
        .task(id: self.photoPickerItems) {
            await self.handleImagesPicked()
        }
        .fileImporter(
            isPresented: self.$isFilePickerPresented,
            allowedContentTypes: [.jpeg, .png, .gif, .webP],
            allowsMultipleSelection: true,
            onCompletion: self.handleFilePicked
        )
        
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                EditButton()
            }
            ToolbarItemGroup {
                if self.uploadsViewModel.isBusy {
                    ProgressView()
                } else {
                    PhotosPicker(selection: self.$photoPickerItems, matching: .images) {
                        Label("Choose photos", systemImage: "rectangle.stack.badge.plus")
                    }
                    Button(action: {
                        self.isFilePickerPresented = true
                    }) {
                       Label("Choose files", systemImage: "filemenu.and.selection")
                    }
                }
            }
        }
    }
}

#if DEBUG
struct UploadContainersListView_Previews: PreviewProvider {
    static var previews: some View {
        UploadContainersListView()
            .environmentObject(GlobalViewModel())
            .environmentObject(UploadsViewModel())
    }
}
#endif
