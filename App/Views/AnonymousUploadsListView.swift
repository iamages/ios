import SwiftUI
import CoreData

struct AnonymousUploadsListView: View {
    struct LoadingError: Identifiable {
        let id: String
        let anonymousUpload: AnonymousUpload
        let error: Error
    }

    @EnvironmentObject private var globalViewModel: GlobalViewModel
    @EnvironmentObject private var splitViewModel: SplitViewModel
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(sortDescriptors: [
        NSSortDescriptor(key: "id", ascending: false)
    ]) private var anonymousUploads: FetchedResults<AnonymousUpload>
    
    @State private var isFirstAppearance: Bool = true
    @State private var isLoading: Bool = true
    @State private var error: LocalizedAlertError?
    @State private var loadingErrors: [LoadingError] = []

    @State private var imageToForget: IamagesImageAndMetadataContainer?
    @State private var anonymousUploadToForget: AnonymousUpload?
    @State private var isConfirmForgetAlertPresented: Bool = false
    
    private func getImage(for anonymousUpload: AnonymousUpload) async throws -> IamagesImageAndMetadataContainer {
        return IamagesImageAndMetadataContainer(
            id: anonymousUpload.id!,
            image: try await self.globalViewModel.getImagePublicMetadata(id: anonymousUpload.id!),
            ownerlessKey: anonymousUpload.ownerlessKey!
        )
    }
    
    private func collectAnonymousImages() async {
        self.isLoading = true
        self.splitViewModel.selectedImage = nil
        self.splitViewModel.images = []
        self.loadingErrors = []
        var images: [IamagesImageAndMetadataContainer] = []
        for anonymousUpload in self.anonymousUploads {
            do {
                images.append(try await self.getImage(for: anonymousUpload))
            } catch {
                self.loadingErrors.append(
                    LoadingError(
                        id: anonymousUpload.id!,
                        anonymousUpload: anonymousUpload,
                        error: error
                    )
                )
            }
        }
        self.splitViewModel.images = images
        self.isLoading = false
    }
    
    private func forgetImage(id: String) async {
        do {
            let fetchRequest = NSFetchRequest<AnonymousUpload>()
            fetchRequest.entity = AnonymousUpload.entity()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id)
            try await self.viewContext.perform {
                for anonymousUpload in try fetchRequest.execute() {
                    self.viewContext.delete(anonymousUpload)
                }
                try self.viewContext.save()
            }
        } catch {
            self.error = LocalizedAlertError(error: error)
        }
    }
    
    private func forgetAnonymousUpload(for anonymousUpload: AnonymousUpload) async {
        await self.viewContext.perform {
            self.viewContext.delete(anonymousUpload)
        }
    }
    
    private func forgetAll() async {
        do {
            try await self.viewContext.perform {
                for anonymousUpload in self.anonymousUploads {
                    self.viewContext.delete(anonymousUpload)
                }
                try self.viewContext.save()
            }
        } catch {
            self.error = LocalizedAlertError(error: error)
        }
    }
    
    @ViewBuilder
    private func getLoadingErrorView(for loadingError: LoadingError) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(loadingError.anonymousUpload.id!)
                    .bold()
                Text(loadingError.error.localizedDescription)
            }
            Spacer()
            Button(role: .destructive) {
                self.anonymousUploadToForget = loadingError.anonymousUpload
            } label: {
                Label("Forget upload", systemImage: "archivebox")
                    .labelStyle(.iconOnly)
            }
        }
    }
    
    @ViewBuilder
    private var list: some View {
        List(selection: self.$splitViewModel.selectedImage) {
            ForEach(self.$splitViewModel.images) { imageAndMetadata in
                NavigableImageView(imageAndMetadata: imageAndMetadata)
                    .contextMenu {
                        Button(role: .destructive, action: {
                            self.imageToForget = imageAndMetadata.wrappedValue
                        }) {
                            Label("Forget image", systemImage: "archivebox")
                        }
                        Button(role: .destructive, action: {
                            self.splitViewModel.imageToDelete = imageAndMetadata.wrappedValue
                        }) {
                            Label("Delete image", systemImage: "trash")
                        }
                    }
            }
            if self.isLoading {
                ProgressView("Loading images...")
            }
            if !self.loadingErrors.isEmpty {
                Section("Errors") {
                    ForEach(self.loadingErrors) { loadingError in
                        self.getLoadingErrorView(for: loadingError)
                    }
                }
            }
        }
        .errorToast(error: self.$error)
        .onReceive(NotificationCenter.default.publisher(for: NSManagedObjectContext.didSaveObjectsNotification)) { output in
            // Deleting anonymous uploads
            Task {
                guard let anonymousUploads = output.userInfo?[NSDeletedObjectsKey] as? Set<AnonymousUpload> else {
                    return
                }
                for anonymousUpload in anonymousUploads {
                    if let i = self.loadingErrors.firstIndex(where: { $0.id == anonymousUpload.id }) {
                        self.loadingErrors.remove(at: i)
                    }
                    if let i = self.splitViewModel.images.firstIndex(where: { $0.id == anonymousUpload.id }) {
                        withAnimation {
                            if self.splitViewModel.selectedImage == anonymousUpload.id {
                                self.splitViewModel.selectedImage = nil
                            }
                            self.splitViewModel.images.remove(at: i)
                        }
                    }
                }
            }
            // Adding new anonymousUploads
            Task {
                guard let anonymousUploads = output.userInfo?[NSInsertedObjectsKey] as? Set<AnonymousUpload> else {
                    return
                }
                self.isLoading = true
                var images: [IamagesImageAndMetadataContainer] = []
                for anonymousUpload in anonymousUploads {
                    do {
                        images.insert(try await self.getImage(for: anonymousUpload), at: 0)
                    } catch {
                        self.loadingErrors.append(
                            LoadingError(
                                id: anonymousUpload.id!,
                                anonymousUpload: anonymousUpload,
                                error: error
                            )
                        )
                    }
                }
                self.splitViewModel.images.insert(contentsOf: images, at: 0)
                self.isLoading = false
            }
        }
        .task {
            if self.isFirstAppearance {
                self.isFirstAppearance = false
                await self.collectAnonymousImages()
            }
        }
        .refreshable {
            if !self.isLoading {
                await self.collectAnonymousImages()
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    self.isConfirmForgetAlertPresented = true
                }) {
                    Label("Forget all", systemImage: "archivebox")
                }
                .confirmationDialog(
                    "Forget all?",
                    isPresented: self.$isConfirmForgetAlertPresented,
                    titleVisibility: .visible
                ) {
                    Button("Forget", role: .destructive) {
                        Task {
                            await self.forgetAll()
                        }
                    }
                } message: {
                    Text("You will never see these again!")
                }
            }
        }
        .alert(
            "Forget image?",
            isPresented: .constant(self.imageToForget != nil),
            presenting: self.imageToForget
        ) { imageAndMetadata in
            Button("Forget", role: .destructive) {
                Task {
                    await self.forgetImage(id: imageAndMetadata.id)
                }
                self.imageToForget = nil
            }
            Button("Cancel", role: .cancel) {
                self.imageToForget = nil
            }
        } message: { imageAndMetadata in
            if let description = imageAndMetadata.metadataContainer?.data.description {
                Text("'\(description)' will be forgotten from this app. People with the link may still access the image.")
            } else {
                Text("The image will be forgotten from this app. People with the link may still access the image.")
            }
        }
        .alert(
            "Forget image?",
            isPresented: .constant(self.anonymousUploadToForget != nil),
            presenting: self.anonymousUploadToForget
        ) { anonymousUpload in
            Button("Forget", role: .destructive) {
                Task {
                    await self.forgetAnonymousUpload(for: anonymousUpload)
                }
                self.anonymousUploadToForget = nil
            }
            Button("Cancel", role: .cancel) {
                self.anonymousUploadToForget = nil
            }
        } message: { anonymousUpload in
            Text("'\(anonymousUpload.id!)' will be forgotten from this app. People with the link may still access the image.")
        }
        .onReceive(NotificationCenter.default.publisher(for: .deleteImage)) { output in
            guard let id = output.object as? String else {
                return
            }
            Task {
                await self.forgetImage(id: id)
            }
        }
    }
    
    var body: some View {
        Group {
            if self.anonymousUploads.isEmpty {
                IconAndInformationView(icon: "archivebox", heading: "No anonymous uploads", subheading: "Let's keep it this way.\nUpload using your account for greater control.")
            } else {
                self.list
            }
        }
        .navigationTitle("Anonymous Uploads")
    }
}

#if DEBUG
struct AnonymousUploadsView_Previews: PreviewProvider {
    static var previews: some View {
        AnonymousUploadsListView()
            .environmentObject(GlobalViewModel())
            .environmentObject(SplitViewModel())
    }
}
#endif
