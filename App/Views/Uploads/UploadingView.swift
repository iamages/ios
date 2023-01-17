import SwiftUI
import NukeUI
import OrderedCollections

struct UploadingView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    @Environment(\.dismiss) private var dismiss

    @Binding var uploadContainers: OrderedDictionary<UUID, IamagesUploadContainer>
    @State private var completedUploads: [IamagesImage] = []
    
    @State private var isCancelUploadsAlertPresented: Bool = false
    
    var body: some View {
        NavigationStack {
            List {
                if !self.completedUploads.isEmpty {
                    Section("Completed") {
                        ScrollView(.horizontal) {
                            LazyHGrid(rows: .init(repeating: GridItem(.fixed(64), spacing: 4), count: 3)) {
                                ForEach(self.completedUploads) { completedUpload in
                                    CompletedUploadView(image: completedUpload)
                                }
                            }
                        }
                    }
                }
                
                if !self.uploadContainers.isEmpty {
                    Section("Uploading") {
                        ForEach(self.uploadContainers.values) { uploadContainer in
                            PendingUploadView(
                                uploadContainer: uploadContainer,
                                completedUploads: self.$completedUploads
                            )
                        }
                    }
                }
            }
            .navigationTitle("Uploading")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        if self.uploadContainers.isEmpty {
                            self.dismiss()
                        } else {
                            self.isCancelUploadsAlertPresented = true
                        }
                    }) {
                        Label("Close", systemImage: "xmark")
                    }
                    .confirmationDialog(
                        "Cancel uploads?",
                        isPresented: self.$isCancelUploadsAlertPresented,
                        titleVisibility: .visible
                    ) {
                        Button("Cancel", role: .destructive) {
                            self.dismiss()
                        }
                        Button("Continue", role: .cancel) {
                            self.isCancelUploadsAlertPresented = false
                        }
                    } message: {
                        Text("Uncompleted uploads will be cancelled.")
                    }
                }
            }
        }
    }
}

#if DEBUG
struct UploadingView_Previews: PreviewProvider {
    static var previews: some View {
        UploadingView(
            uploadContainers: .constant([:])
        )
        .environmentObject(GlobalViewModel())
    }
}
#endif
