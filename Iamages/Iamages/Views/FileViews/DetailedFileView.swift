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

struct DetailedFileView: View {
    @EnvironmentObject var dataObservable: APIDataObservable
    @Environment(\.presentationMode) var presentationMode

    @Binding var file: IamagesFile
    @Binding var feed: [IamagesFile]
    let type: FeedType
    
    @State var isBusy: Bool = false
    @State var isDeleted: Bool = false
    @State var isDetailSheetPresented: Bool = false
    @State var isShareSheetPresented: Bool = false
    @State var isModifyFileSheetPresented: Bool = false
    @State var isDeleteAlertPresented: Bool = false
    @State var isSetProfilePictureAlertPresented: Bool = false
    @State var isDeleteFileFailAlertPresented: Bool = false
    
    @State var fileToSave: ImageDocument?
    @State var fileNameToSave: String?
    @State var isSaveFileSheetPresented: Bool = false
    @State var isSaveFileSuccessAlertPresented: Bool = false
    @State var isSaveFileFailAlertPresented: Bool = false
    
    func setAsProfilePicture () async {
        self.isBusy = true
        do {
            try await self.dataObservable.modifyAppUser(modify: .pfp(self.file.id))
        } catch {
            
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
            self.isDeleteFileFailAlertPresented = true
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
                        if success {
                            self.isSaveFileSuccessAlertPresented = true
                        } else {
                            self.isSaveFileFailAlertPresented = true
                        }
                    })
                case .toFileDocument:
                    if let fileExtension = UTType(mimeType: self.file.mime)?.preferredFilenameExtension {
                        self.fileNameToSave = "iamages-\(self.file.id).\(fileExtension)"
                        self.fileToSave = ImageDocument(initialImageData: response.originalData)
                        self.isSaveFileSheetPresented = true
                    }
                }
            case .failure(_):
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
    
    func reportContent () {
        UIApplication.shared.open(URL(
            string: "mailto:iamages@uber.space?subject=\("Report file: \(self.file.id)".urlEncode())&body=\("Reason:".urlEncode())"
        )!)
    }

    var body: some View {
        if self.isDeleted {
            Label("File has been deleted. Pick something else on the side to view.", systemImage: "trash")
        } else {
            ZoomableScrollComponent {
                KFAnimatedImage(self.dataObservable.getFileImageURL(id: self.file.id))
                    .placeholder {
                        ProgressView()
                    }
                    .cancelOnDisappear(true)
                    .scaledToFit()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if self.isBusy {
                        ProgressView()
                    }
                }
                ToolbarItem(placement: .principal) {
                    Button(action: {
                        self.isDetailSheetPresented = true
                    }) {
                        Label("Details", systemImage: "info.circle")
                    }
                    .disabled(self.isBusy)
                }
                ToolbarItem {
                    Menu(content: {
                        #if targetEnvironment(macCatalyst)
                        Button(action: self.copyLink) {
                            Label("Copy link", systemImage: "link")
                        }
                        #else
                        Button(action: {
                            self.isShareSheetPresented = true
                        }) {
                            Label("Share link", systemImage: "square.and.arrow.up")
                        }
                        #endif
                        Divider()
                        Menu(content: {
                            ForEach(FileSaveMethod.allCases, id: \.self) { method in
                                Button(method.rawValue) {
                                    self.save(method: method)
                                }
                            }
                        }) {
                            Label("Save", systemImage: "square.and.arrow.down")
                        }
                        if self.file.owner != nil &&
                           self.file.owner! == self.dataObservable.currentAppUser?.username {
                            Divider()
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
                            .disabled(self.dataObservable.currentAppUserInformation?.pfp == self.file.id)
                        }
                        if self.file.owner != nil &&
                           self.file.owner! == self.dataObservable.currentAppUser?.username &&
                           !self.file.isPrivate
                        {
                            Divider()
                            Button(action: {
                                self.isSetProfilePictureAlertPresented = true
                            }) {
                                Label("Set as profile picture", systemImage: "person.crop.circle")
                            }
                        }
                        Divider()
                        Button(action: self.reportContent) {
                            Label("Report content", systemImage: "exclamationmark.bubble")
                        }
                    }) {
                        Label("Actions", systemImage: "ellipsis.circle")
                    }
                    .menuStyle(.borderlessButton)
                    .disabled(self.isBusy)
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
                }
            }
            .sheet(isPresented: self.$isDetailSheetPresented) {
                ImageDetailView(file: self.$file, isDetailSheetPresented: self.$isDetailSheetPresented)
            }
            .sheet(isPresented: self.$isModifyFileSheetPresented) {
                ModifyFileView(file: self.$file, feed: self.$feed, type: self.type, isModifyFileSheetPresented: self.$isModifyFileSheetPresented)
            }
            #if !targetEnvironment(macCatalyst)
            .sheet(isPresented: self.$isShareSheetPresented) {
                ShareView(activityItems: [self.dataObservable.getFileEmbedURL(id: self.file.id)])
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
            .alert("File save successful", isPresented: self.$isSaveFileSuccessAlertPresented, actions: {}, message: "The file has been saved to your selected destination.")
            .alert("File save failed", isPresented: self.$isSaveFileFailAlertPresented, actions: {}, message: "")
            .navigationBarBackButtonHidden(self.isBusy)
        }
    }
}

struct DetailedFileView_Previews: PreviewProvider {
    static var previews: some View {
        DetailedFileView(file: .constant(IamagesFile(id: "", description: "", isNSFW: false, isPrivate: false, isHidden: false, created: Date(), mime: "", width: 0, height: 0)), feed: .constant([]), type: .publicFeed)
    }
}
