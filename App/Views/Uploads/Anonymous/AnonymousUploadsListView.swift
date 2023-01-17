import SwiftUI
import CoreData

struct AnonymousUploadsListView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    @EnvironmentObject private var splitViewModel: SplitViewModel
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(key: "addedOn", ascending: false)
        ]
    ) private var anonymousUploads: FetchedResults<AnonymousUpload>
    
    @State private var error: LocalizedAlertError?
    @State private var imageToDelete: AnonymousUpload?
    @State private var imageToForget: AnonymousUpload?
    @State private var isConfirmDeleteAlertPresented: Bool = false
    @State private var isConfirmForgetAlertPresented: Bool = false
    
    private func deleteImage(for anonymousUpload: AnonymousUpload) async {
        do {
            try await self.globalViewModel.fetchData(
                "/images/\(anonymousUpload.id!)",
                method: .delete,
                headers: [
                    "X-Iamages-Ownerless-Key": anonymousUpload.ownerlessKey!.uuidString
                ]
            )
            try await self.viewContext.perform {
                self.viewContext.delete(anonymousUpload)
                try self.viewContext.save()
            }
        } catch {
            self.error = LocalizedAlertError(error: error)
        }
    }
    
    private func forgetImage(for anonymousUpload: AnonymousUpload) async {
        do {
            try await self.viewContext.perform {
                self.viewContext.delete(anonymousUpload)
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
        List(self.anonymousUploads, selection: self.$splitViewModel.selectedImage) { anonymousUpload in
            NavigableAnonymousUploadView(
                anonymousUpload: anonymousUpload
            )
            .contextMenu {
                ShareLink(item: .apiRootUrl.appending(path: "/images/\(anonymousUpload.id!)/embed")) {
                    Label("Share image...", systemImage: "square.and.arrow.up")
                }
                Divider()
                Button(role: .destructive, action: {
                    self.imageToDelete = anonymousUpload
                }) {
                    Label("Delete image", systemImage: "trash")
                }
                Button(role: .destructive, action: {
                    self.imageToForget = anonymousUpload
                }) {
                    Label("Forget image", systemImage: "archivebox")
                }
            }
        }
        .errorAlert(error: self.$error)
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
            "Delete image?",
            isPresented: .constant(self.imageToDelete != nil),
            presenting: self.imageToDelete
        ) { anonymousUpload in
            Button("Delete", role: .destructive) {
                Task {
                    await self.deleteImage(for: anonymousUpload)
                }
                self.imageToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                self.imageToDelete = nil
            }
        } message: { _ in
            Text("The image will be deleted permanently!")
        }
        .alert(
            "Forget image?",
            isPresented: .constant(self.imageToForget != nil),
            presenting: self.imageToForget
        ) { anonymousUpload in
            Button("Forget", role: .destructive) {
                Task {
                    await self.forgetImage(for: anonymousUpload)
                }
                self.imageToForget = nil
            }
            Button("Cancel", role: .cancel) {
                self.imageToForget = nil
            }
        } message: { _ in
            Text("The image will be forgotten from this app. People with the link may still access the image.")
        }
        .alert(
            "Delete image?",
            isPresented: .constant(self.imageToDelete != nil),
            presenting: self.imageToDelete
        ) { anonymousUpload in
            Button("Delete", role: .destructive) {
                Task {
                    await self.deleteImage(for: anonymousUpload)
                }
                self.imageToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                self.imageToDelete = nil
            }
        } message: { _ in
            Text("The image will be deleted permanently!")
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
