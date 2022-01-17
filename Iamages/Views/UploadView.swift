import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct UploadView: View {
    @EnvironmentObject var dataObservable: APIDataObservable
    
    @AppStorage("uploadDefaults.isNSFW") var isNSFWDefault: Bool = false
    @AppStorage("uploadDefaults.isHidden") var isHiddenDefault: Bool = false
    @AppStorage("uploadDefaults.isPrivate") var isPrivateDefault: Bool = false
    
    @State var photoPickerResults: [PHPickerResult] = []
    @State var isPhotoPickerPresented: Bool = false
    @State var isFilePickerPresented: Bool = false
    @State var isURLPickerPresented: Bool = false
    @State var isNewUploadCollectionSheetPresented: Bool = false
    @State var isUploadingFilesListSheetPresented: Bool = false
    
    @State var pickedURL: URL?
    
    @State var pickErrorAlertText: String?
    @State var isPickErrorAlertPresented: Bool = false
    
    @State var uploadRequests: [UploadFileRequest] = []
    @State var uploadMode: UploadMode = .separate
    @State var newCollection: NewCollectionRequest = NewCollectionRequest(description: "No description yet.", isPrivate: false, isHidden: false)

    @State var isThirdPanePresented: Bool = true
    
    var body: some View {
        List {
            ForEach(self.$uploadRequests) { uploadRequest in
                NavigableModifyUploadRequestView(uploadRequest: uploadRequest)
            }
            .onDelete { offset in
                self.isThirdPanePresented = true
                self.uploadRequests.remove(atOffsets: offset)
            }
            .onMove { indexSet, offset in
                self.uploadRequests.move(fromOffsets: indexSet, toOffset: offset)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                EditButton()
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Menu(content: {
                    Button(action: {
                        self.isPhotoPickerPresented = true
                    }) {
                        Label("Select photos", systemImage: "photo.on.rectangle")
                    }
                    Button(action: {
                        self.isFilePickerPresented = true
                        self.dataObservable.isModalPresented = true
                    }) {
                        Label("Select files", systemImage: "doc")
                    }
                    Button(action: {
                        self.isURLPickerPresented = true
                    }) {
                        Label("Save from URLs", systemImage: "externaldrive.badge.icloud")
                    }
                }) {
                    Label("Select", systemImage: "rectangle.stack.badge.plus")
                }
                .menuStyle(.borderlessButton)
            }
            ToolbarItem(placement: .primaryAction) {
                Menu(content: {
                    Button(action: {
                        self.uploadMode = .separate
                        self.isUploadingFilesListSheetPresented = true
                    }) {
                        Label("Upload separately", systemImage: "square.and.arrow.up.on.square")
                    }
                    Button(action: {
                        self.uploadMode = .toCollection
                        self.isNewUploadCollectionSheetPresented = true
                    }) {
                        Label("Upload to new collection", systemImage: "square.grid.3x1.folder.badge.plus")
                    }
                }) {
                    Label("Upload", systemImage: "square.and.arrow.up")
                }
                .disabled(self.uploadRequests.isEmpty)
                .menuStyle(.borderlessButton)
            }
        }
        .customSheet(isPresented: self.$isPhotoPickerPresented) {
            PhotosPickerView(pickerResults: self.$photoPickerResults, isPresented: self.$isPhotoPickerPresented)
                .onDisappear {
                    self.photoPickerResults.forEach { photoPickerResult in
                        let provider = photoPickerResult.itemProvider
                        if let typeIdentifier: String = provider.registeredTypeIdentifiers.first {
                            if provider.canLoadObject(ofClass: UIImage.self) {
                                provider.loadDataRepresentation(forTypeIdentifier: typeIdentifier, completionHandler: { data, error in
                                    if let data = data {
                                        if data.count < 50000000 {
                                            self.uploadRequests.append(
                                                UploadFileRequest(
                                                    info: UploadJSONRequest(
                                                        description: "No description yet.",
                                                        isNSFW: self.isNSFWDefault,
                                                        isPrivate: self.isPrivateDefault,
                                                        isHidden: self.isHiddenDefault,
                                                        url: nil
                                                    ),
                                                    file: UploadFile(
                                                        image: data,
                                                        type: UTType(typeIdentifier)!
                                                    )
                                                )
                                            )
                                        } else {
                                            self.pickErrorAlertText = "Photo file size for '\(photoPickerResult.assetIdentifier ?? "unknown")' is larger than 50Mb (\(data.count)"
                                            self.isPickErrorAlertPresented = true
                                        }
                                    } else if let error = error {
                                        self.pickErrorAlertText = error.localizedDescription
                                        self.isPickErrorAlertPresented = true
                                    }
                                })
                            }
                        }
                    }
                    self.photoPickerResults = []
                }
            
        }
        .fileImporter(
            isPresented: self.$isFilePickerPresented,
            allowedContentTypes: [.image],
            allowsMultipleSelection: true
        ) { result in
            self.dataObservable.isModalPresented = false
            switch result {
                case .success(let urls):
                do {
                    for url in urls {
                        if let bytes = FileManager.default.sizeOfFile(atPath: url.path) {
                            if bytes < 50000000 {
                                let image = try Data(contentsOf: url)
                                self.uploadRequests.append(
                                    UploadFileRequest(
                                        info: UploadJSONRequest(
                                            description: "No description yet.",
                                            isNSFW: self.isNSFWDefault,
                                            isPrivate: self.isPrivateDefault,
                                            isHidden: self.isHiddenDefault,
                                            url: nil
                                        ),
                                        file: UploadFile(
                                            image: image,
                                            type: UTType(filenameExtension: url.pathExtension)!
                                        )
                                    )
                                )
                            } else {
                                self.pickErrorAlertText = "File size for '\(url.path)' is larger than 50Mb! (\(bytes) bytes)"
                                self.isPickErrorAlertPresented = true
                            }
                        }
                    }
                } catch {
                    self.pickErrorAlertText = error.localizedDescription
                    self.isPickErrorAlertPresented = true
                }
                case .failure(let error):
                self.pickErrorAlertText = error.localizedDescription
                self.isPickErrorAlertPresented = true
            }
        }
        .customSheet(isPresented: self.$isURLPickerPresented) {
            URLPickerView(pickedURL: self.$pickedURL, isPresented: self.$isURLPickerPresented)
                .onDisappear {
                    if self.pickedURL != nil {
                        self.uploadRequests.append(
                            UploadFileRequest(
                                info: UploadJSONRequest(
                                    description: "No description yet",
                                    isNSFW: self.isNSFWDefault,
                                    isPrivate: self.isPrivateDefault,
                                    isHidden: self.isHiddenDefault,
                                    url: self.pickedURL!
                                ),
                                file: nil
                            )
                        )
                    }
                }
        }
        .customSheet(isPresented: self.$isUploadingFilesListSheetPresented) {
            UploadingFilesListView(uploadRequests: self.$uploadRequests, mode: self.$uploadMode, newCollection: self.$newCollection, isPresented: self.$isUploadingFilesListSheetPresented)
        }
        .customSheet(isPresented: self.$isNewUploadCollectionSheetPresented) {
            UploadingNewCollectionView(newCollection: self.$newCollection, isPresented: self.$isNewUploadCollectionSheetPresented)
                .onDisappear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.isUploadingFilesListSheetPresented = true
                    }
                }
        }
        .customBindingAlert(title: "File pick failed", message: self.$pickErrorAlertText, isPresented: self.$isPickErrorAlertPresented)
        .listAndDetailViewFix(isThirdPanePresented: self.$isThirdPanePresented)
        .navigationTitle("Upload")
    }
}
