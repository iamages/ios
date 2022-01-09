import SwiftUI
import UniformTypeIdentifiers

struct UploadView: View {
    @EnvironmentObject var dataObservable: APIDataObservable
    
    @AppStorage("uploadDefaults.isNSFW") var isNSFWDefault: Bool = false
    @AppStorage("uploadDefaults.isHidden") var isHiddenDefault: Bool = false
    @AppStorage("uploadDefaults.isPrivate") var isPrivateDefault: Bool = false
    
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
    
    #if targetEnvironment(macCatalyst)
    @State var isThirdPanePresented: Bool = true
    #endif
    
    var body: some View {
        List {
            ForEach(self.$uploadRequests) { uploadRequest in
                NavigableModifyUploadRequestView(uploadRequest: uploadRequest, uploadRequests: self.$uploadRequests)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Menu(content: {
                    Button(action: {
                        self.isPhotoPickerPresented = true
                        self.dataObservable.isModalPresented = true
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
                        self.dataObservable.isModalPresented = true
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
                        self.dataObservable.isModalPresented = true
                    }) {
                        Label("Upload separately", systemImage: "square.and.arrow.up.on.square")
                    }
                    Button(action: {
                        self.uploadMode = .toCollection
                        self.isNewUploadCollectionSheetPresented = true
                        self.dataObservable.isModalPresented = true
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
        .sheet(isPresented: self.$isPhotoPickerPresented, onDismiss: {
            self.dataObservable.isModalPresented = false
        }) {
            PhotosPickerView(imageRetrievedHandler: { image, type in
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
                            type: UTType(type)!
                        )
                    )
                )
            }, isPresented: self.$isPhotoPickerPresented)
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
                    }
                } catch {
                    print(error)
                }
                case .failure(let error):
                self.pickErrorAlertText = error.localizedDescription
                self.isPickErrorAlertPresented = true
            }
        }
        .sheet(isPresented: self.$isURLPickerPresented, onDismiss: {
            self.dataObservable.isModalPresented = false
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
        }) {
            URLPickerView(pickedURL: self.$pickedURL, isPresented: self.$isURLPickerPresented)
        }
        .sheet(isPresented: self.$isUploadingFilesListSheetPresented, onDismiss: {
            self.dataObservable.isModalPresented = false
        }) {
            UploadingFilesListView(uploadRequests: self.$uploadRequests, mode: self.$uploadMode, newCollection: self.$newCollection, isPresented: self.$isUploadingFilesListSheetPresented)
        }
        .sheet(isPresented: self.$isNewUploadCollectionSheetPresented, onDismiss: {
            self.dataObservable.isModalPresented = false
            // Tiny delay for weird Mac Catalyst sheet slow dismiss.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.isUploadingFilesListSheetPresented = true
                self.dataObservable.isModalPresented = true
            }
        }) {
            UploadingNewCollectionView(newCollection: self.$newCollection, isPresented: self.$isNewUploadCollectionSheetPresented)
        }
        .navigationTitle("Upload")
        #if targetEnvironment(macCatalyst)
        .background {
            NavigationLink(destination: RemovedSuggestView(), isActive: self.$isThirdPanePresented) {
                EmptyView()
            }
        }
        #endif
    }
}
