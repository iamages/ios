import SwiftUI
import CoreData

struct AnonymousUploadsListView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    @EnvironmentObject private var splitViewModel: SplitViewModel
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(key: "id", ascending: false)
        ]
    ) private var anonymousUploads: FetchedResults<AnonymousUpload>
    
    @State private var error: LocalizedAlertError?

    @State private var imageToForget: String?
    @State private var isConfirmForgetAlertPresented: Bool = false
    
    private func getImage(id: String) async {
        do {
            self.splitViewModel.images.insert(
                IamagesImageAndMetadataContainer(
                    id: id,
                    image: try await self.globalViewModel.getImagePublicMetadata(id: id)
                ),
                at: 0
            )
        } catch {
            self.error = LocalizedAlertError(error: error)
        }
    }
    
    private func forgetImage(id: String) async {
        do {
            var fetchRequest = NSFetchRequest<AnonymousUpload>()
            fetchRequest.predicate = NSPredicate(format: "id == %s", id)
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
            ForEach(self.$splitViewModel.images) { image in
                NavigableImageView(imageAndMetadata: image)
                    .contextMenu {
                        Button(role: .destructive, action: {
                            self.imageToForget = image.id
                            self.isConfirmForgetAlertPresented = true
                        }) {
                            Label("Forget image", systemImage: "archivebox")
                        }
                    }
            }
        }
        .errorToast(error: self.$error)
        .task {
            for anonymousUpload in self.anonymousUploads {
                await self.getImage(id: anonymousUpload.id!)
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
        ) { id in
            Button("Forget", role: .destructive) {
                Task {
                    await self.forgetImage(id: id)
                }
                self.imageToForget = nil
            }
            Button("Cancel", role: .cancel) {
                self.imageToForget = nil
            }
        } message: { _ in
            Text("The image will be forgotten from this app. People with the link may still access the image.")
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
