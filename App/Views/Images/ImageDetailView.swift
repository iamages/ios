import SwiftUI
import NukeUI
import WidgetKit
import AlertToast

struct ImageDetailView: View {
    enum SaveTarget {
        case file
        case library
    }
    
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    @EnvironmentObject private var splitViewModel: SplitViewModel
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("selectedWidgetImageId", store: .iamagesGroup) var selectedWidgetImageId: String?
    
    @Binding var imageAndMetadata: IamagesImageAndMetadataContainer
    
    @State private var previousIsLocked: Bool = false
    
    @State private var request: ImageRequest?
    @State private var key: String = ""
    @State private var isKeyAlertPresented: Bool = false
    @State private var shouldAttemptUnlock: Bool = false
    
    @State private var isInformationSheetPresented: Bool = false
    @State private var isEditInformationSheetPresented: Bool = false
    @State private var isCollectionPickerSheetPresented: Bool = false
    
    @State private var isBusy: Bool = false
    @State private var isDownloadingToastPresented: Bool = false
    @State private var isFileExporterPresented = false
    @State private var savableImageDocument: SavedImageDocument?
    @State private var isDownloadSuccessAlertPresented: Bool = false
    @State private var error: LocalizedAlertError?
    
    private var selectedImageTitle: String {
        if let metadata = self.imageAndMetadata.metadataContainer?.data {
            if self.imageAndMetadata.image.lock.isLocked && self.scenePhase == .inactive {
                return NSLocalizedString("Locked image", comment: "")
            }
            return metadata.description
        } else {
            if self.imageAndMetadata.image.lock.isLocked {
                return NSLocalizedString("Locked image", comment: "")
            } else {
                return NSLocalizedString("Loading metadata...", comment: "")
            }
        }
    }
    
    private var canPerformOwnerTasks: Bool {
        if let username = self.globalViewModel.userInformation?.username {
            return self.imageAndMetadata.image.owner == username
        }
        return false
    }
    
    // Fetches metadata and image key salt
    private func getMetadata() async {
        self.isBusy = true
        
        do {
            let metadata = try await self.globalViewModel.getImagePrivateMetadata(
                for: self.imageAndMetadata.image,
                key: self.key.isEmpty ? nil : self.key
            )
            withAnimation {
                self.imageAndMetadata.metadataContainer = metadata
            }
            if self.imageAndMetadata.image.lock.isLocked {
                guard let salt = try await self.globalViewModel.fetchData(
                    "/images/\(self.imageAndMetadata.image.id)\(self.imageAndMetadata.image.file.typeExtension)",
                    method: .head,
                    authStrategy: self.imageAndMetadata.image.isPrivate ? .required : .none
                ).1.value(forHTTPHeaderField: "X-Iamages-Lock-Salt")?.data(using: .utf8) else {
                    throw NoSaltError()
                }
                self.imageAndMetadata.image.file.salt = Data(base64Encoded: salt)
            }
        } catch {
            self.error = LocalizedAlertError(error: error)
        }
        
        self.isBusy = false
    }
    
    private func toggleWidgetImage(id: String) {
        if self.selectedWidgetImageId == id {
            self.selectedWidgetImageId = nil
        } else {
            self.selectedWidgetImageId = id
        }
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.selected.rawValue)
    }
    
    private func resetView() {
        self.key = ""
        self.request = nil
    }
    
    private func saveImage(to target: SaveTarget) async {
        let data: Data
        if let cachedData = ImagePipeline.shared.cache.cachedData(for: self.request!) {
            data = cachedData
        } else {
            do {
                self.isDownloadingToastPresented = true
                data = try await self.globalViewModel.fetchData(
                    "/images/\(self.imageAndMetadata.id)\(self.imageAndMetadata.image.file.typeExtension)",
                    method: .get,
                    authStrategy: self.imageAndMetadata.image.isPrivate ? .required : .none
                ).0
                self.isDownloadingToastPresented = false
            } catch {
                self.isDownloadingToastPresented = false
                self.error = LocalizedAlertError(error: error)
                return
            }
        }
        switch target {
        case .file:
            self.savableImageDocument = SavedImageDocument(data: data)
            self.isFileExporterPresented = true
        case .library:
            ImageSaver.writeToPhotoAlbum(data: data)
        }
    }
    
    @ViewBuilder
    private var lockView: some View {
        IconAndInformationView(
            icon: "lock.doc.fill",
            heading: "Image is locked",
            additionalViews: AnyView(
                Group {
                    if self.isBusy {
                        ProgressView()
                    } else {
                        Button("Unlock") {
                            self.isKeyAlertPresented = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            )
        )
        .task(id: self.isKeyAlertPresented) {
            if !self.isKeyAlertPresented && self.shouldAttemptUnlock {
                await self.getMetadata()
                self.request = self.globalViewModel.getImageRequest(
                    for: self.imageAndMetadata.image,
                    key: self.key
                )
                self.shouldAttemptUnlock = false
            }
        }
        .alert("Lock key required", isPresented: self.$isKeyAlertPresented) {
            SecureField("Lock key", text: self.$key)
            Button("Unlock", role: .destructive) {
                self.shouldAttemptUnlock = true
                self.isKeyAlertPresented = false
            }
            Button("Cancel", role: .cancel) {
                self.isKeyAlertPresented = false
            }
        } message: {
            Text("This image is locked, input your lock key below to unlock it.")
        }
    }
    
    @ViewBuilder
    private var imageView: some View {
        LazyImage(request: self.request) { state in
            if let image = state.image {
                image
                    .resizingMode(.aspectFit)
            } else if let error = state.error {
                IconAndInformationView(
                    icon: "exclamationmark.octagon.fill",
                    heading: "Couldn't get image",
                    subheading: error.localizedDescription,
                    additionalViews: AnyView(
                        Button("Retry") {
                            self.request = nil
                        }
                            .buttonStyle(.borderedProminent)
                    )
                )
            } else {
                ProgressView()
            }
        }
    }
    
    var body: some View {
        Group {
            if self.request == nil {
                if self.imageAndMetadata.image.lock.isLocked {
                    self.lockView
                } else {
                    ProgressView()
                        .onAppear {
                            self.request = self.globalViewModel.getImageRequest(
                                for: self.imageAndMetadata.image
                            )
                        }
                }
            } else {
                ZoomableScrollView {
                    self.imageView
                }
            }
        }
        .errorAlert(error: self.$error)
        .toast(isPresenting: self.$isDownloadingToastPresented) {
            AlertToast(displayMode: .alert, type: .loading, title: "Downloading...")
        }
        .alert("Image downloaded", isPresented: self.$isDownloadSuccessAlertPresented) {
            // Use default OK button.
        } message: {
            Text("The image bas been saved to your selected location")
        }
        .fileExporter(
            isPresented: self.$isFileExporterPresented,
            document: self.savableImageDocument,
            contentType: self.imageAndMetadata.image.file.contentType,
            defaultFilename: "\(self.imageAndMetadata.id)\(self.imageAndMetadata.image.file.typeExtension)"
        ) { result in
            switch result {
            case .success(_):
                self.isDownloadSuccessAlertPresented = true
            case .failure(let error):
                self.error = LocalizedAlertError(error: error)
            }
            self.savableImageDocument = nil
        }
        .onChange(of: self.isFileExporterPresented) { isPresented in
            if !isPresented {
                self.savableImageDocument = nil
            }
        }
        .onDisappear(perform: self.resetView)
        .onChange(of: self.splitViewModel.selectedImage) { _ in
            self.resetView()
        }
        .sheet(isPresented: self.$isInformationSheetPresented) {
            ImageInformationView(
                imageAndMetadata: self.$imageAndMetadata
            )
        }
        .sheet(isPresented: self.$isEditInformationSheetPresented) {
            EditImageInformationView(
                imageAndMetadata: self.$imageAndMetadata
            )
        }
        .sheet(isPresented: self.$isCollectionPickerSheetPresented) {
            CollectionsListView(
                viewMode: .picker,
                imageID: self.imageAndMetadata.image.id
            )
        }
        .userActivity(
            NSUserActivityTypeBrowsingWeb,
            element: self.imageAndMetadata
        ) { imageAndMetadata, activity in
            activity.isEligibleForHandoff = true
            activity.webpageURL = self.globalViewModel.getImageEmbedURL(id: imageAndMetadata.id)
        }
        .navigationTitle(self.selectedImageTitle)
        .navigationBarTitleDisplayMode(.inline)
        #if targetEnvironment(macCatalyst)
        .navigationSubtitle(self.selectedImageTitle)
        #endif
        .toolbarRole(.editor)
        .toolbar(id: "imageDetail") {
            ToolbarItem(id: "share", placement: .primaryAction) {
                ImageShareLinkView(image: self.imageAndMetadata.image)
            }
            ToolbarItem(id: "information", placement: .secondaryAction) {
                Button(action: {
                    self.isInformationSheetPresented = true
                }) {
                    Label("Information", systemImage: "info.circle")
                }
            }
            ToolbarItem(id: "edit", placement: .secondaryAction) {
                Button(action: {
                    self.isEditInformationSheetPresented = true
                }) {
                    Label("Edit", systemImage: "pencil")
                }
                .disabled(!self.canPerformOwnerTasks)
            }
            ToolbarItem(id: "delete", placement: .secondaryAction) {
                Button(role: .destructive, action: {
                    self.splitViewModel.imageToDelete = self.imageAndMetadata
                }) {
                    Label("Delete", systemImage: "trash")
                }
                .disabled(
                    !self.canPerformOwnerTasks &&
                    self.imageAndMetadata.ownerlessKey == nil
                )
            }
            ToolbarItem(id: "save", placement: .secondaryAction) {
                ControlGroup {
                    Button {
                        Task {
                            await self.saveImage(to: .file)
                        }
                    } label: {
                        Label("Save to file", systemImage: "arrow.down.doc")
                    }
                    Button {
                        Task {
                            await self.saveImage(to: .library)
                        }
                    } label: {
                        Label("Save to photos library", systemImage: "photo.on.rectangle.angled")
                    }
                } label: {
                    Label("Save", systemImage: "square.and.arrow.down")
                }
                .disabled(self.imageAndMetadata.image.lock.isLocked || self.isDownloadingToastPresented)
            }
            ToolbarItem(id: "addToCollection", placement: .secondaryAction) {
                Button(action: {
                    self.isCollectionPickerSheetPresented = true
                }) {
                    Label("Add to collection", systemImage: "folder.badge.plus")
                }
                .disabled(!self.globalViewModel.isLoggedIn)
            }
            ToolbarItem(id: "toggleWidgetImage", placement: .secondaryAction) {
                Button(action: {
                    self.toggleWidgetImage(id: self.imageAndMetadata.image.id)
                }) {
                    if self.selectedWidgetImageId == self.imageAndMetadata.image.id {
                        Label("Unset widget image", systemImage: "rectangle.slash")
                    } else {
                        Label("Set widget image", systemImage: "rectangle")
                    }
                }
                .disabled(self.imageAndMetadata.image.lock.isLocked)
            }
            ToolbarItem(id: "relock", placement: .secondaryAction) {
                if self.imageAndMetadata.image.lock.isLocked {
                    Button(role: .destructive, action: self.resetView) {
                        Label("Relock", systemImage: "lock")
                    }
                    .disabled(self.request == nil)
                }
            }
        }
    }
}

#if DEBUG
struct ImageDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ImageDetailView(
            imageAndMetadata: .constant(previewImageAndMetadata)
        )
        .environmentObject(GlobalViewModel())
        .environmentObject(SplitViewModel())
    }
}
#endif
