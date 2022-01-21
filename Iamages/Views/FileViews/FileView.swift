import SwiftUI
import UniformTypeIdentifiers
import Kingfisher
import Photos

fileprivate enum FileSaveMethod: String, CaseIterable {
    case toPhotoLibrary = "To photo library"
    case toFileDocument = "To file"
}

struct ImageDocument: FileDocument {
    static var readableContentTypes: [UTType] = [.image]
    static var writableContentTypes: [UTType] = [.image]
    
    var imageData: Data = Data()
    
    init (initialImageData: Data) {
        self.imageData = initialImageData
    }
    
    init (configuration: ReadConfiguration) throws {
        if let imageData = configuration.file.regularFileContents {
            self.imageData = imageData
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: self.imageData)
    }
}

struct FileView: View {
    @EnvironmentObject var dataObservable: APIDataObservable
    @Environment(\.presentationMode) var presentationMode

    @Binding var file: IamagesFile
    @Binding var feed: [IamagesFile]
    let type: FeedType
    
    @State var isBusy: Bool = false
    @State var isDeleted: Bool = false

    @State var isInfoSheetPresented: Bool = false
    #if !targetEnvironment(macCatalyst)
    @State var isShareSheetPresented: Bool = false
    #endif
    @State var isModifyFileSheetPresented: Bool = false

    @State var isDeleteAlertPresented: Bool = false
    @State var deleteFileErrorText: String?
    @State var isDeleteFileErrorAlertPresented: Bool = false

    @State var isSetProfilePictureAlertPresented: Bool = false
    @State var setProfilePictureErrorText: String?
    @State var isSetProfilePictureErrorAlertPresented: Bool = false
    
    @State var isPickCollectionSheetPresented: Bool = false
    @State var pickedCollectionID: String?
    @State var addToCollectionErrorText: String?
    @State var isAddToCollectionErrorAlertPresented: Bool = false
    
    @State var fileToSave: ImageDocument?
    @State var fileNameToSave: String?
    @State var isSaveFileSheetPresented: Bool = false
    @State var isSaveFileSuccessAlertPresented: Bool = false
    @State var saveFileFailMessage: String?
    @State var isSaveFileFailAlertPresented: Bool = false
    
    func setAsProfilePicture () async {
        self.isBusy = true
        do {
            try await self.dataObservable.modifyAppUser(modify: .pfp(self.file.id))
        } catch {
            self.setProfilePictureErrorText = error.localizedDescription
            self.isSetProfilePictureErrorAlertPresented = true
        }
        self.isBusy = false
    }
    
    func delete () async {
        self.isBusy = true
        do {
            try await self.dataObservable.deleteFile(file: self.file)
            if let fileIndex = self.feed.firstIndex(of: self.file) {
                self.feed.remove(at: fileIndex)
            }
            self.isDeleted = true
            self.presentationMode.wrappedValue.dismiss()
        } catch {
            self.isBusy = false
            self.deleteFileErrorText = error.localizedDescription
            self.isDeleteFileErrorAlertPresented = true
        }
    }
    
    fileprivate func save (method: FileSaveMethod) {
        self.isBusy = true
        KingfisherManager.shared.downloader.downloadImage(with: self.dataObservable.getFileImageURL(id: self.file.id)) { result in
            switch result {
            case .success(let response):
                switch method {
                case .toPhotoLibrary:
                    PHPhotoLibrary.shared().performChanges({
                        let creationRequest = PHAssetCreationRequest.forAsset()
                        creationRequest.addResource(with: .photo, data: response.originalData, options: nil)
                    }, completionHandler: { success, error in
                        if error != nil {
                            self.saveFileFailMessage = error!.localizedDescription
                            self.isSaveFileFailAlertPresented = true
                        } else {
                            self.isSaveFileSuccessAlertPresented = true
                        }
                    })
                case .toFileDocument:
                    if let fileExtension = UTType(mimeType: self.file.mime)?.preferredFilenameExtension {
                        self.fileNameToSave = "iamages-\(self.file.id).\(fileExtension)"
                        self.fileToSave = ImageDocument(initialImageData: response.originalData)
                        self.isSaveFileSheetPresented = true
                    }
                }
            case .failure(let error):
                self.saveFileFailMessage = error.localizedDescription
                self.isSaveFileFailAlertPresented = true
            }
            self.isBusy = false
        }
    }
    
    func copyLink () {
        UIPasteboard.general.setValue(
            self.dataObservable.getFileEmbedURL(id: self.file.id),
            forPasteboardType: "public.url"
        )
    }
    
    func report () {
        UIApplication.shared.open(URL(
            string: "mailto:iamages@uber.space?subject=\("Report file: \(self.file.id)".urlEncode())&body=\("Reason:".urlEncode())"
        )!)
    }
    
    func checkBelongsToUser () -> Bool {
        return self.file.owner != nil && self.file.owner! == self.dataObservable.currentAppUser?.username
    }
    
    func checkAlreadyProfilePicture () -> Bool {
        return self.dataObservable.currentAppUserInformation?.pfp == self.file.id
    }
    
    func addToCollection () async {
        self.isBusy = true
        do {
            try await self.dataObservable.modifyCollection(id: self.pickedCollectionID!, modify: .addFile(self.file.id))
        } catch {
            self.addToCollectionErrorText = error.localizedDescription
            self.isAddToCollectionErrorAlertPresented = true
        }
        self.isBusy = false
    }

    var body: some View {
        if self.isDeleted {
            RemovedSuggestView()
        } else {
            ZoomableScrollView {
                KFAnimatedImage(self.dataObservable.getFileImageURL(id: self.file.id))
                    .placeholder {
                        ProgressView()
                    }
                    .cancelOnDisappear(true)
                    .scaledToFit()
                    .onDrag {
                        return NSItemProvider(item: self.dataObservable.getFileEmbedURL(id: self.file.id) as NSSecureCoding, typeIdentifier: "public.url")
                    }
            }
            .toolbar {
                ToolbarItem(placement: .status) {
                    if self.isBusy {
                        ProgressView()
                    }
                }
                ToolbarItem(placement: .principal) {
                    Button(action: {
                        self.isInfoSheetPresented = true
                    }) {
                        Label("Info", systemImage: "info.circle")
                    }
                    .disabled(self.isBusy)
                    .keyboardShortcut("i")
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu(content: {
                        Section {
                            #if targetEnvironment(macCatalyst)
                            Button("Copy link") {
                                self.copyLink()
                            }
                            #else
                            Button(action: {
                                self.isShareSheetPresented = true
                            }) {
                                Label("Share link", systemImage: "square.and.arrow.up")
                            }
                            #endif
                        }

                        Section {
                            Menu(content: {
                                ForEach(FileSaveMethod.allCases, id: \.self) { method in
                                    Button(method.rawValue) {
                                        self.save(method: method)
                                    }
                                }
                            }) {
                                Label("Save", systemImage: "square.and.arrow.down")
                            }
                        }
                        
                        if self.checkBelongsToUser() {
                            Section {
                                Button(action: {
                                    self.isModifyFileSheetPresented = true
                                }) {
                                    Label("Modify", systemImage: "pencil")
                                }
                                Button(role: .destructive, action: {
                                    self.isDeleteAlertPresented = true
                                }) {
                                    Label("Delete", systemImage: "trash")
                                }
                                .disabled(self.checkAlreadyProfilePicture())
                            }
                        }
                        if self.checkBelongsToUser() && !self.file.isPrivate {
                            Section {
                                Button(action: {
                                    self.isSetProfilePictureAlertPresented = true
                                }) {
                                    Label("Set as profile picture", systemImage: "person.crop.circle")
                                }
                                .disabled(self.checkAlreadyProfilePicture())
                            }
                        }
                        if self.dataObservable.isLoggedIn && !self.file.isPrivate {
                            Section {
                                Button(action: {
                                    self.isPickCollectionSheetPresented = true
                                }) {
                                    Label("Add to collection", systemImage: "rectangle.stack.badge.plus")
                                }
                            }
                        }
                        Section {
                            Button(action: self.report) {
                                Label("Report file", systemImage: "exclamationmark.bubble")
                            }
                        }
                    }) {
                        Label("Actions", systemImage: "ellipsis.circle")
                    }
                    .confirmationDialog(
                        "'\(self.file.description)' will be deleted.",
                        isPresented: self.$isDeleteAlertPresented,
                        titleVisibility: .visible
                    ) {
                        Button("Delete", role: .destructive) {
                            Task {
                                await self.delete()
                            }
                        }
                    }
                    .confirmationDialog(
                        "'\(self.file.description)' will be set as your profile picture.",
                        isPresented: self.$isSetProfilePictureAlertPresented,
                        titleVisibility: .visible
                    ) {
                        Button("Set as profile picture") {
                            Task {
                                await self.setAsProfilePicture()
                            }
                        }
                    }
                    .menuStyle(.borderlessButton)
                    .disabled(self.isBusy)
                }
            }
            .customSheet(isPresented: self.$isInfoSheetPresented) {
                FileInfoView(file: self.$file, isPresented: self.$isInfoSheetPresented)
            }
            .customSheet(isPresented: self.$isModifyFileSheetPresented) {
                ModifyFileInfoView(file: self.$file, feed: self.$feed, type: self.type, isDeleted: self.$isDeleted, isPresented: self.$isModifyFileSheetPresented)
            }
            .customSheet(isPresented: self.$isPickCollectionSheetPresented) {
                UserCollectionPickerView(pickedCollectionID: self.$pickedCollectionID, isPresented: self.$isPickCollectionSheetPresented)
                    .onDisappear {
                        if self.pickedCollectionID != nil {
                            Task {
                                await self.addToCollection()
                            }
                        }
                    }
            }
            #if !targetEnvironment(macCatalyst)
            .customSheet(isPresented: self.$isShareSheetPresented) {
                ShareView(activityItems: [self.dataObservable.getFileEmbedURL(id: self.file.id)], isPresented: self.$isShareSheetPresented)
            }
            #endif
            .fileExporter(
                isPresented: self.$isSaveFileSheetPresented,
                document: self.fileToSave,
                contentType: .image,
                defaultFilename: self.fileNameToSave
            ) { result in
                switch result {
                case .success(_):
                    self.isSaveFileSuccessAlertPresented = true
                case .failure(_):
                    self.isSaveFileFailAlertPresented = true
                }
            }
            .customFixedAlert(title: "File save successfully", message: "The file has been saved to your selected destination.", isPresented: self.$isSaveFileSuccessAlertPresented)
            .customBindingAlert(title: "File save failed", message: self.$saveFileFailMessage, isPresented: self.$isSaveFileFailAlertPresented)
            .customBindingAlert(title: "Delete failed", message: self.$deleteFileErrorText, isPresented: self.$isDeleteFileErrorAlertPresented)
            .customBindingAlert(title: "Set profile picture failed", message: self.$setProfilePictureErrorText, isPresented: self.$isSetProfilePictureErrorAlertPresented)
            .customBindingAlert(title: "Add to collection failed", message: self.$addToCollectionErrorText, isPresented: self.$isAddToCollectionErrorAlertPresented)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(self.isBusy)
        }
    }
}
