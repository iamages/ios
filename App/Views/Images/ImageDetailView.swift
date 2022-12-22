import SwiftUI
import NukeUI
import WidgetKit

struct ImageDetailView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    @Environment(\.openWindow) private var openWindow
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("selectedWidgetImageId", store: .iamagesGroup) var selectedWidgetImageId: String?
    
    @ObservedObject var splitViewModel: SplitViewModel

    @State private var request: ImageRequest?
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
        guard let selectedImage = self.splitViewModel.selectedImage else {
            return ""
        }
        if let metadata = self.splitViewModel.selectedImageMetadata {
            if selectedImage.lock.isLocked && self.scenePhase == .inactive {
                return NSLocalizedString("Locked image", comment: "")
            }
            return metadata.description
        } else {
            if selectedImage.lock.isLocked {
                return NSLocalizedString("Locked image", comment: "")
            } else {
                return NSLocalizedString("Loading metadata...", comment: "")
            }
        }
    }
    
    private func fetchMetadata(image: IamagesImage) async {
        self.isBusy = true

        do {
            self.splitViewModel.selectedImageMetadata = try await self.globalViewModel.getImagePrivateMetadata(
                for: image,
                key: self.key.isEmpty ? nil : self.key
            )
        } catch {
            self.error = LocalizedAlertError(error: error)
        }
        
        self.isBusy = false
    }
    
    private func delete() async {
        self.isBusy = true
        
        do {
            guard let id = self.splitViewModel.selectedImage?.id else {
                throw NoIDError()
            }
            try await self.globalViewModel.fetchData(
                "/images/\(id)",
                method: .delete,
                authStrategy: .required
            )
            NotificationCenter.default.post(name: .deleteImage, object: id)
            self.splitViewModel.selectedImage = nil
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

    private func lock(for image: IamagesImage) -> some View {
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
                await self.fetchMetadata(image: image)
                self.request = self.globalViewModel.getImageRequest(for: image, key: self.key)
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
        self.splitViewModel.selectedImageMetadata = nil
        self.request = nil
    }
    
    var body: some View {
        if let image = self.splitViewModel.selectedImage {
            Group {
                if self.request == nil {
                    if image.lock.isLocked {
                        self.lock(for: image)
                    } else {
                        ProgressView()
                            .task {
                                await self.fetchMetadata(image: image)
                                self.request = self.globalViewModel.getImageRequest(for: image)
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
            .onDisappear(perform: self.resetView)
            .onChange(of: self.splitViewModel.selectedImage) { _ in
                self.resetView()
            }
            .sheet(isPresented: self.$isInformationSheetPresented) {
                ImageInformationView(
                    isPresented: self.$isInformationSheetPresented,
                    splitViewModel: self.splitViewModel
                )
            }
            .sheet(isPresented: self.$isEditInformationSheetPresented) {
                EditImageInformationView(
                    isPresented: self.$isEditInformationSheetPresented,
                    splitViewModel: self.splitViewModel
                )
            }
            .sheet(isPresented: self.$isCollectionPickerSheetPresented) {
                CollectionsListView(
                    splitViewModel: self.splitViewModel,
                    viewMode: .picker,
                    imageID: image.id,
                    isPresented: self.$isCollectionPickerSheetPresented
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
                    ShareLink(item: self.globalViewModel.getImageEmbedURL(id: image.id))
                        .disabled(image.isPrivate)
                }
                ToolbarItem(id: "toggleWidgetImage", placement: .secondaryAction) {
                    Button(action: {
                        self.toggleWidgetImage(id: image.id)
                    }) {
                        if self.selectedWidgetImageId == image.id {
                            Label("Unset widget image", systemImage: "rectangle.slash")
                        } else {
                            Label("Set widget image", systemImage: "rectangle")
                        }
                    }
                    .disabled(image.lock.isLocked)
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
                    if image.lock.isLocked {
                        Button(role: .destructive, action: {
                            self.request = nil
                            self.splitViewModel.selectedImageMetadata = nil
                        }) {
                            Label("Relock", systemImage: "lock")
                        }
                        .disabled(self.request == nil)
                    }
                }
            }
        } else {
            Text("Select an image from the sidebar")
                .navigationTitle("")
        }
    }
}

#if DEBUG
struct ImageDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ImageDetailView(splitViewModel: SplitViewModel())
            .environmentObject(GlobalViewModel())
    }
}
#endif
