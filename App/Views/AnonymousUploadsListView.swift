import SwiftUI
import CoreData

struct AnonymousUploadsListView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    @EnvironmentObject private var splitViewModel: SplitViewModel
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(sortDescriptors: [
        NSSortDescriptor(key: "id", ascending: true)
    ]) private var anonymousUploads: FetchedResults<AnonymousUpload>
    
    @State private var isFirstAppearance: Bool = true
    @State private var error: LocalizedAlertError?

    @State private var imageToForget: IamagesImageAndMetadataContainer?
    @State private var isConfirmForgetAlertPresented: Bool = false
    
    private func getImage(for anonymousUpload: AnonymousUpload) async {
        do {
            self.splitViewModel.images.insert(
                IamagesImageAndMetadataContainer(
                    id: anonymousUpload.id!,
                    image: try await self.globalViewModel.getImagePublicMetadata(id: anonymousUpload.id!),
                    ownerlessKey: anonymousUpload.ownerlessKey!
                ),
                at: 0
            )
        } catch {
            self.error = LocalizedAlertError(error: error)
        }
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
        }
        .errorToast(error: self.$error)
        .onReceive(NotificationCenter.default.publisher(for: NSManagedObjectContext.didSaveObjectsNotification)) { output in
            guard let anonymousUploads = output.userInfo?[NSInsertedObjectsKey] as? Set<AnonymousUpload> else {
                return
            }
            for anonymousUpload in anonymousUploads {
                Task {
                    await self.getImage(for: anonymousUpload)
                }
            }
        }
        .task {
            if self.isFirstAppearance {
                self.isFirstAppearance = false
                for anonymousUpload in self.anonymousUploads {
                    await self.getImage(for: anonymousUpload)
                }
            }
        }
        .refreshable {
            self.splitViewModel.selectedImage = nil
            self.splitViewModel.images = []
            for anonymousUpload in self.anonymousUploads {
                await self.getImage(for: anonymousUpload)
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
