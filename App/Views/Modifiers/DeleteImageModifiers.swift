import SwiftUI
import CoreData

struct DeleteImageListenerModifier: ViewModifier {
    @ObservedObject var splitViewModel: SplitViewModel
    
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .deleteImage)) { output in
                guard let id = output.object as? String,
                      let i = self.splitViewModel.images.firstIndex(where: { $0.id == id }) else {
                    return
                }
                if self.splitViewModel.selectedImage == id {
                    withAnimation {
                        self.splitViewModel.selectedImage = nil
                    }
                }
                withAnimation {
                    self.splitViewModel.images.remove(at: i)
                }
            }
    }
}

struct DeleteImageAlertModifier: ViewModifier {
    @ObservedObject var splitViewModel: SplitViewModel
    @ObservedObject var globalViewModel: GlobalViewModel
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var error: LocalizedAlertError?
    
    func body(content: Content) -> some View {
        content
            .errorAlert(error: self.$error)
            .alert(
                "Delete image?",
                isPresented: .constant(self.splitViewModel.imageToDelete != nil),
                presenting: self.splitViewModel.imageToDelete
            ) { imageAndMetadata in
                Button("Delete", role: .destructive) {
                    Task {
                        do {
                            var headers: [String: String] = [:]
                            if let ownerlessKey = imageAndMetadata.ownerlessKey {
                                headers["X-Iamages-Ownerless-Key"] = ownerlessKey.uuidString
                            }
                            try await self.globalViewModel.fetchData(
                                "/images/\(imageAndMetadata.id)",
                                method: .delete,
                                headers: headers,
                                authStrategy: headers.isEmpty ? .required : .none
                            )
                            let fetchRequest = NSFetchRequest<AnonymousUpload>()
                            fetchRequest.entity = AnonymousUpload.entity()
                            fetchRequest.predicate = NSPredicate(format: "id == %@", imageAndMetadata.id)
                            try await self.viewContext.perform {
                                for anonymousUpload in try fetchRequest.execute() {
                                    self.viewContext.delete(anonymousUpload)
                                }
                                try self.viewContext.save()
                            }
                            NotificationCenter.default.post(
                                name: .deleteImage,
                                object: imageAndMetadata.id
                            )
                        } catch {
                            self.error = LocalizedAlertError(error: error)
                        }
                    }
                    self.splitViewModel.imageToDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    self.splitViewModel.imageToDelete = nil
                }
            } message: { imageAndMetadata in
                if let description = imageAndMetadata.metadataContainer?.data.description {
                    Text("'\(description)' will be deleted!")
                } else {
                    Text("The selected image will be deleted!")
                }
            }
    }
}
