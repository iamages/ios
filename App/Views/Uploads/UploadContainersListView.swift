import SwiftUI
import PhotosUI

struct UploadContainersListView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    @Environment(\.editMode) private var editMode
    
    @Binding var selectedUploadContainer: UUID?
    @Binding var uploadContainers: [IamagesUploadContainer]
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
                self.uploadContainers.append(container)
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

                    self.uploadContainers.append(container)
                } catch {
                    self.fileImportErrors.append(IdentifiableLocalizedError(error: error as! LocalizedError))
                }
            }
        case .failure(let error):
            self.error = LocalizedAlertError(error: error)
        }
        
        self.isBusy = false
    }
    
    private func deleteUpload(id: UUID) {
        if let i = self.uploadContainers.firstIndex(where: { $0.id == id }) {
            withAnimation {
                self.uploadContainers.remove(at: i)
            }
        }
    }
    
    @ViewBuilder
    private func deleteUploadButton(id: UUID) -> some View {
        Button(role: .destructive, action: {
            self.deleteUpload(id: id)
        }) {
            Label("Delete upload", systemImage: "trash")
        }
    }
    
    var body: some View {
        Group {
            if self.uploadContainers.isEmpty {
                IconAndInformationView(
                    icon: "questionmark.folder",
                    heading: "No images added"
                )
            } else {
                List(selection: self.$selectedUploadContainer) {
                    ForEach(self.uploadContainers) { uploadContainer in
                        NavigableUploadContainerView(
                            uploadContainer: uploadContainer
                        )
                        .contextMenu {
                            self.deleteUploadButton(id: uploadContainer.id)
                        }
                    }
                    .onDelete { offsets in
                        self.uploadContainers.remove(atOffsets: offsets)
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .deleteUpload)) { output in
                    if let id = output.object as? UUID {
                        if self.selectedUploadContainer == id {
                            self.selectedUploadContainer = nil
                        }
                        self.deleteUpload(id: id)
                    }
                }
            }
        }
        .navigationTitle("Uploads")
        .navigationBarTitleDisplayMode(.inline)
        #if targetEnvironment(macCatalyst)
        .navigationSubtitle("\(self.uploadContainers.count) image\(self.uploadContainers.count > 1 || self.uploadContainers.isEmpty ? "s" : "")")
        #endif
        .errorAlert(error: self.$error)
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
