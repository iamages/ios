import SwiftUI
import NukeUI
import WidgetKit

struct ImageDetailView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    @EnvironmentObject private var splitViewModel: SplitViewModel
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("selectedWidgetImageId", store: .iamagesGroup) var selectedWidgetImageId: String?
    
    @Binding var imageAndMetadata: IamagesImageAndMetadataContainer

    @State private var request: ImageRequest?
    @State private var imageLockKeySalt: Data?
    @State private var key: String = ""
    @State private var isKeyAlertPresented: Bool = false
    @State private var shouldAttemptUnlock: Bool = false

    @State private var isInformationSheetPresented: Bool = false
    @State private var isEditInformationSheetPresented: Bool = false
    @State private var isCollectionPickerSheetPresented: Bool = false

    @State private var isDeleteDialogPresented: Bool = false
    @State private var isBusy: Bool = false
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
    
    // Fetches metadata and image key salt
    private func fetchMetadata(image: IamagesImage) async {
        self.isBusy = true

        do {
            self.imageAndMetadata.metadataContainer = try await self.globalViewModel.getImagePrivateMetadata(
                for: image,
                key: self.key.isEmpty ? nil : self.key
            )
            if image.lock.isLocked {
                guard let salt = try await self.globalViewModel.fetchData(
                    "/images/\(image.id)/download",
                    method: .head,
                    authStrategy: image.isPrivate ? .required : .none
                ).1.value(forHTTPHeaderField: "X-Iamages-Lock-Salt")?.data(using: .utf8) else {
                    throw NoSaltError()
                }
                self.imageLockKeySalt = Data(base64Encoded: salt)
            }
            
        } catch {
            self.error = LocalizedAlertError(error: error)
        }
        
        self.isBusy = false
    }
    
    private func delete() async {
        self.isBusy = true
        
        do {
            try await self.globalViewModel.fetchData(
                "/images/\(self.imageAndMetadata.image.id)",
                method: .delete,
                authStrategy: .required
            )
            NotificationCenter.default.post(
                name: .deleteImage,
                object: self.imageAndMetadata.image.id
            )
            self.isBusy = false
        } catch {
            self.isBusy = false
            self.error = LocalizedAlertError(error: error)
        }
    }
    
    private func toggleWidgetImage(id: String) {
        if self.selectedWidgetImageId == id {
            self.selectedWidgetImageId = nil
        } else {
            self.selectedWidgetImageId = id
        }
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.selected.rawValue)
    }

    @ViewBuilder
    private var lock: some View {
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
                await self.fetchMetadata(image: self.imageAndMetadata.image)
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
    
    private func resetView() {
        self.key = ""
        self.imageLockKeySalt = nil
        self.request = nil
        self.splitViewModel.isDetailViewVisible = false
    }
    
    var body: some View {
        Group {
            if self.request == nil {
                if self.imageAndMetadata.image.lock.isLocked {
                    self.lock
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
        .navigationTitle(self.selectedImageTitle)
        .navigationBarTitleDisplayMode(.inline)
        #if targetEnvironment(macCatalyst)
        .navigationSubtitle(self.selectedImageTitle)
        #endif
        .onAppear {
            self.splitViewModel.isDetailViewVisible = true
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
                imageAndMetadata: self.$imageAndMetadata,
                imageLockKeySalt: self.$imageLockKeySalt
            )
        }
        .sheet(isPresented: self.$isCollectionPickerSheetPresented) {
            CollectionsListView(
                viewMode: .picker,
                imageID: self.imageAndMetadata.image.id
            )
        }
        .toolbarRole(.editor)
        .toolbar(id: "imageDetail") {
            ToolbarItem(id: "information", placement: .primaryAction) {
                Button(action: {
                    self.isInformationSheetPresented = true
                }) {
                    Label("Information", systemImage: "info.circle")
                }
            }
            ToolbarItem(id: "share", placement: .secondaryAction) {
                ImageShareLinkView(image: self.imageAndMetadata.image)
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
            ToolbarItem(id: "addToCollection", placement: .secondaryAction) {
                Button(action: {
                    self.isCollectionPickerSheetPresented = true
                }) {
                    Label("Add to collection", systemImage: "folder.badge.plus")
                }
            }
            ToolbarItem(id: "edit", placement: .secondaryAction) {
                Button(action: {
                    self.isEditInformationSheetPresented = true
                }) {
                    Label("Edit", systemImage: "pencil")
                }
                .disabled(self.imageAndMetadata.image.lock.isLocked && self.imageLockKeySalt == nil)
            }
            ToolbarItem(id: "delete", placement: .secondaryAction) {
                Button(role: .destructive, action: {
                    self.isDeleteDialogPresented = true
                }) {
                    Label("Delete", systemImage: "trash")
                }
                .confirmationDialog("Delete image?", isPresented: self.$isDeleteDialogPresented, titleVisibility: .visible) {
                    Button("Delete", role: .destructive) {
                        Task {
                            await self.delete()
                        }
                    }
                    Button("Cancel", role: .cancel) {
                        self.isDeleteDialogPresented = false
                    }
                } message: {
                    Text("You cannot revert this action.")
                }
            }
            ToolbarItem(id: "relock", placement: .secondaryAction) {
                if self.imageAndMetadata.image.lock.isLocked {
                    Button(role: .destructive, action: {
                        self.request = nil
                        self.imageAndMetadata.metadataContainer = nil
                    }) {
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
