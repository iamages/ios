import SwiftUI
import PhotosUI
import OrderedCollections

struct UploadContainersListView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    @Environment(\.editMode) private var editMode
    
    @Binding var selectedUploadContainer: UUID?
    @Binding var uploadContainers: OrderedDictionary<UUID, IamagesUploadContainer>
    @Binding var fileImportErrors: [IdentifiableLocalizedError]
    @Binding var isBusy: Bool
    
    @State private var error: LocalizedAlertError?

    @State private var isFilePickerPresented: Bool = false
    @State private var photoPickerItems: [PhotosPickerItem] = []

    private func handleImagesPicked() async {
        self.isBusy = true
        
        for image in self.photoPickerItems {
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
                
                let container = IamagesUploadContainer(
                    file: IamagesUploadFile(
                        data: data,
                        type: mime
                    )
                )
                
                self.uploadContainers[container.id] = container
            } catch {
                if let error = error as? LocalizedError {
                    self.fileImportErrors.append(IdentifiableLocalizedError(error: error))
                }
                
            }
        }
        self.photoPickerItems = []
        
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
                    
                    let container = IamagesUploadContainer(
                        file: IamagesUploadFile(
                            data: try Data(contentsOf: url),
                            type: type
                        )
                    )

                    self.uploadContainers[container.id] = container
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
                    ForEach(self.uploadContainers.values) { uploadContainer in
                        NavigableUploadContainerView(
                            uploadContainer: uploadContainer
                        )
                    }
                }
            }
        }
        .navigationTitle("Uploads")
        #if targetEnvironment(macCatalyst)
        .navigationSubtitle("\(self.uploadContainers.count) image\(self.uploadContainers.count > 1 || self.uploadContainers.isEmpty ? "s" : "")")
        #endif
        .errorAlert(error: self.$error)
        .onChange(of: self.photoPickerItems) { _ in
            Task {
                await self.handleImagesPicked()
            }
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
            uploadContainers: .constant([:]),
            fileImportErrors: .constant([]),
            isBusy: .constant(false)
        )
        .environmentObject(GlobalViewModel())
    }
}
#endif
