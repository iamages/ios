import SwiftUI
import PhotosUI

struct UploadView: View {
    @EnvironmentObject var viewModel: ViewModel
    
    #if !os(macOS)
    @Binding var isPresented: Bool
    #endif
    
    @State private var pendingUploads: [IamagesUploadContainer] = []

    @State private var images: [PhotosPickerItem] = []
    
    @State private var isFilePickerPresented: Bool = false
    @State private var error: LocalizedAlertError?
    
    @State private var isBusy: Bool = false

    @State private var fileImportErrors: [IdentifiableLocalizedError] = []
    @State private var isImportErrorsSheetPresented: Bool = false
    
    private func handleImagesPicked(_ images: [PhotosPickerItem]) async {
        self.isBusy = true
        
        for i in (0..<images.count).reversed() {
            let image: PhotosPickerItem = images[i]
            
            do {
                guard let data: Data = try await image.loadTransferable(type: Data.self) else {
                    throw FileImportErrors.loadPhotoFromLibraryFailure
                }
                guard let type: UTType = image.supportedContentTypes.first else {
                    throw FileImportErrors.noType("Photo library file")
                }
                
                if !self.viewModel.acceptedFileTypes.contains(type) {
                    throw FileImportErrors.unsupportedType("Photo library file", type)
                }
                
                self.pendingUploads.append(
                    IamagesUploadContainer(
                        file: IamagesUploadFile(
                            filename: "\(image.itemIdentifier ?? UUID().uuidString).\(type.preferredFilenameExtension ?? ".bin")",
                            data: data,
                            type: type
                        )
                    )
                )
            } catch {
                self.fileImportErrors.append(IdentifiableLocalizedError(error: error as! LocalizedError))
            }

            self.images.remove(at: i)
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

                    guard let type: UTType = meta.contentType else {
                        throw FileImportErrors.noType(url.lastPathComponent)
                    }
                    if !self.viewModel.acceptedFileTypes.contains(type) {
                        throw FileImportErrors.unsupportedType(url.lastPathComponent, type)
                    }

                    self.pendingUploads.append(
                        IamagesUploadContainer(
                            file: IamagesUploadFile(
                                filename: url.lastPathComponent,
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
                if self.pendingUploads.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "questionmark.folder")
                            .font(.largeTitle)
                        Text("No images added")
                            .font(.title2)
                            .bold()
                    }
                } else {
                    List {
                        ForEach(self.$pendingUploads) { pendingUpload in
                            NavigableUploadInformationView(
                                information: pendingUpload.information,
                                image: pendingUpload.file.data.wrappedValue
                            )
                            .listRowSeparator(.visible)
                        }
                        .onDelete { offset in
                            self.pendingUploads.remove(atOffsets: offset)
                        }
                    }
                }
            }
            .navigationTitle("Uploads")
            #if os(macOS)
            .navigationSubtitle("\(self.pendingUploads.count) image\(self.pendingUploads.count > 1 || self.pendingUploads.isEmpty ? "s" : "")")
            #endif
            .onChange(of: self.images) { images in
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
            .toolbar {
                #if !os(macOS)
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
                #if os(iOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                        .disabled(self.pendingUploads.isEmpty)
                }
                #endif
                ToolbarItem(placement: .primaryAction) {
                    PhotosPicker(selection: self.$images, matching: .images) {
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
                            
                        }) {
                            Label("Upload separately", systemImage: "square.and.arrow.up.on.square")
                        }
                        Button(action: {
                            
                        }) {
                            Label("Upload into collection", systemImage: "square.grid.3x1.folder.badge.plus")
                        }
                    } label: {
                        Label("Upload", systemImage: "square.and.arrow.up.on.square")
                    }
                    .disabled(self.images.isEmpty)
                }
            }
            .errorAlert(error: self.$error)
        }
    }
}

#if DEBUG
struct UploadView_Previews: PreviewProvider {
    static var previews: some View {
        #if os(macOS)
        UploadView()
            .environmentObject(ViewModel())
        #else
        UploadView(isPresented: .constant(true))
            .environmentObject(ViewModel())
        #endif
    }
}
#endif
