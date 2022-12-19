import SwiftUI
import PhotosUI

struct UploadContainersListView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    @Environment(\.editMode) private var editMode
    
    @Binding var selectedUploadContainer: IamagesUploadContainer?
    @Binding var uploadContainers: [IamagesUploadContainer]
    @Binding var fileImportErrors: [IdentifiableLocalizedError]
    @Binding var isBusy: Bool
    
    @State private var error: LocalizedAlertError?

    @State private var isFilePickerPresented: Bool = false
    @State private var photoPickerItems: [PhotosPickerItem] = []

    private func handleImagesPicked(_ images: [PhotosPickerItem]) async {
        self.isBusy = true
        
        for i in (0..<images.count).reversed() {
            let image: PhotosPickerItem = images[i]
            
            do {
                guard let data: Data = try await image.loadTransferable(type: Data.self) else {
                    throw FileImportErrors.loadPhotoFromLibraryFailure
                }
                guard let type: UTType = image.supportedContentTypes.first,
                      let mime: String = type.preferredMIMEType else {
                    throw FileImportErrors.noType("Photo library file")
                }
                
                if !self.globalViewModel.acceptedFileTypes.contains(mime) {
                    throw FileImportErrors.unsupportedType("Photo library file", mime)
                }
                
                self.uploadContainers.append(
                    IamagesUploadContainer(
                        file: IamagesUploadFile(
                            name: "\(image.itemIdentifier ?? UUID().uuidString).\(type.preferredFilenameExtension ?? ".bin")",
                            data: data,
                            type: mime
                        )
                    )
                )
            } catch {
                if let error = error as? LocalizedError {
                    self.fileImportErrors.append(IdentifiableLocalizedError(error: error))
                }
                
            }

            self.photoPickerItems.remove(at: i)
        }
        
        self.isBusy = false
    }
    
    private func handleFilePicked(_ result: Result<[URL], Error>) {
        self.isBusy = true

        switch result {
        case .success(let urls):
            for url in urls {
                do {
                    let meta = try url.resourceValues(forKeys: [.fileSizeKey, .contentTypeKey])

                    guard let size: Int = meta.fileSize else {
                        throw FileImportErrors.noSize(url.lastPathComponent)
                    }
                    if size > 10485760 {
                        throw FileImportErrors.tooLarge(url.lastPathComponent, size)
                    }

                    guard let type: String = meta.contentType?.preferredMIMEType else {
                        throw FileImportErrors.noType(url.lastPathComponent)
                    }
                    if !self.globalViewModel.acceptedFileTypes.contains(type) {
                        throw FileImportErrors.unsupportedType(url.lastPathComponent, type)
                    }

                    self.uploadContainers.append(
                        IamagesUploadContainer(
                            file: IamagesUploadFile(
                                name: url.lastPathComponent,
                                data: try Data(contentsOf: url),
                                type: type
                            )
                        )
                    )
                } catch {
                    self.fileImportErrors.append(IdentifiableLocalizedError(error: error as! LocalizedError))
                }
            }
        case .failure(let error):
            self.error = LocalizedAlertError(error: error)
        }
        
        self.isBusy = false
    }
    
    var body: some View {
        Group {
            if self.uploadContainers.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "questionmark.folder")
                        .font(.largeTitle)
                    Text("No images added")
                        .font(.title2)
                        .bold()
                }
            } else {
                List(selection: self.$selectedUploadContainer) {
                    ForEach(self.$uploadContainers) { uploadContainer in
                        NavigableUploadContainerView(
                            uploadContainer: uploadContainer
                        )
                        .disabled(self.selectedUploadContainer != nil)
                    }
                    .onDelete { offset in
                        for i in offset {
                            if self.uploadContainers[i].id == self.selectedUploadContainer?.id {
                                self.selectedUploadContainer = nil
                            }
                        }
                        self.uploadContainers.remove(atOffsets: offset)
                    }
                }
            }
        }
        .navigationTitle("Uploads")
        #if targetEnvironment(macCatalyst)
        .navigationSubtitle("\(self.uploadContainers.count) image\(self.uploadContainers.count > 1 || self.uploadContainers.isEmpty ? "s" : "")")
        #endif
        .errorAlert(error: self.$error)
        .onChange(of: self.photoPickerItems) { images in
            Task {
                await self.handleImagesPicked(images)
            }
        }
        .fileImporter(
            isPresented: self.$isFilePickerPresented,
            allowedContentTypes: [.jpeg, .png, .gif, .webP, .svg],
            allowsMultipleSelection: true,
            onCompletion: self.handleFilePicked
        )
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                EditButton()
            }
            ToolbarItem {
                PhotosPicker(selection: self.$photoPickerItems, matching: .images) {
                    Label("Choose photos", systemImage: "rectangle.stack.badge.plus")
                }
            }
            ToolbarItem {
                Button(action: {
                    self.isFilePickerPresented = true
                }) {
                   Label("Choose files", systemImage: "filemenu.and.selection")
                }
            }
        }
    }
}

#if DEBUG
struct UploadContainersListView_Previews: PreviewProvider {
    static var previews: some View {
        UploadContainersListView(
            selectedUploadContainer: .constant(nil),
            uploadContainers: .constant([]),
            fileImportErrors: .constant([]),
            isBusy: .constant(false)
        )
        .environmentObject(GlobalViewModel())
    }
}
#endif
