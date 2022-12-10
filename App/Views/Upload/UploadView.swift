import SwiftUI
import PhotosUI

struct UploadView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel

    #if !targetEnvironment(macCatalyst)
    @Binding var isPresented: Bool
    #endif
    
    @State private var uploadContainers: [IamagesUploadContainer] = []

    @State private var photoPickerItems: [PhotosPickerItem] = []
    
    @State private var isFilePickerPresented: Bool = false
    @State private var error: LocalizedAlertError?
    
    @State private var isBusy: Bool = false

    @State private var fileImportErrors: [IdentifiableLocalizedError] = []
    @State private var isImportErrorsSheetPresented: Bool = false
    
    // TODO: Collection information
    @State private var isNewCollectionSheetPresented: Bool = false
    @State private var isNavigatedToUploading: Bool = false
    
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
        NavigationStack {
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
                    List {
                        ForEach(self.$uploadContainers) { pendingUpload in
                            NavigableUploadInformationView(
                                uploadContainer: pendingUpload
                            )
                            .listRowSeparator(.visible)
                        }
                        .onDelete { offset in
                            self.uploadContainers.remove(atOffsets: offset)
                        }
                    }
                }
            }
            .navigationTitle("Uploads")
            #if targetEnvironment(macCatalyst)
            .navigationSubtitle("\(self.uploadContainers.count) image\(self.uploadContainers.count > 1 || self.uploadContainers.isEmpty ? "s" : "")")
            #endif
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
            .sheet(isPresented: self.$isImportErrorsSheetPresented) {
                UploadImportErrorsView(
                    errors: self.$fileImportErrors,
                    isPresented: self.$isImportErrorsSheetPresented
                )
            }
            .sheet(isPresented: self.$isNewCollectionSheetPresented, onDismiss: {
                self.isNavigatedToUploading = true
            }) {
                
            }
            .navigationDestination(isPresented: self.$isNavigatedToUploading) {
                UploadingView(uploadContainers: self.$uploadContainers)
            }
            .toolbar {
                #if !targetEnvironment(macCatalyst)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        self.isPresented = false
                    }) {
                        Label("Close", systemImage: "xmark")
                    }
                    .keyboardShortcut("w", modifiers: .command)
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
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                        .disabled(self.uploadContainers.isEmpty)
                }
                ToolbarItem(placement: .primaryAction) {
                    PhotosPicker(selection: self.$photoPickerItems, matching: .images) {
                        Label("Choose photos", systemImage: "rectangle.stack.badge.plus")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        self.isFilePickerPresented = true
                    }) {
                       Label("Choose files", systemImage: "filemenu.and.selection")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: {
                            self.isNavigatedToUploading = true
                        }) {
                            Label("Upload separately", systemImage: "square.and.arrow.up.on.square")
                        }
                        Button(action: {
                            self.isNewCollectionSheetPresented = true
                        }) {
                            Label("Upload into collection", systemImage: "square.grid.3x1.folder.badge.plus")
                        }
                    } label: {
                        Label("Upload", systemImage: "square.and.arrow.up.on.square")
                    }
                    .disabled(self.uploadContainers.isEmpty)
                }
            }
            .errorAlert(error: self.$error)
        }
    }
}

#if DEBUG
struct UploadView_Previews: PreviewProvider {
    static var previews: some View {
        #if targetEnvironment(macCatalyst)
        UploadView()
            .environmentObject(GlobalViewModel())
        #else
        UploadView(isPresented: .constant(true))
            .environmentObject(GlobalViewModel())
        #endif
    }
}
#endif
