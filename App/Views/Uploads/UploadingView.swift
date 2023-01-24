import SwiftUI
import NukeUI

struct UploadingView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    @Environment(\.dismiss) private var dismiss

    @Binding var uploadContainers: [IamagesUploadContainer]
    @State private var completedUploads: [IamagesImage] = []
    
    @State private var isCancelUploadsAlertPresented: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading) {
                    if !self.completedUploads.isEmpty {
                        Text("Completed")
                            .bold()
                            .foregroundColor(.gray)
                        ScrollView(.horizontal) {
                            LazyHGrid(rows: [GridItem(.fixed(64), spacing: 4)]) {
                                ForEach(self.completedUploads) { completedUpload in
                                    CompletedUploadView(image: completedUpload)
                                }
                            }
                        }
                    }
                    if !self.uploadContainers.isEmpty {
                        Text("Uploading")
                            .bold()
                            .foregroundColor(.gray)
                        ForEach(self.uploadContainers) { uploadContainer in
                            PendingUploadView(
                                uploadContainer: uploadContainer,
                                completedUploads: self.$completedUploads
                            )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Uploading")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
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
            uploadContainers: .constant([])
        )
        .environmentObject(GlobalViewModel())
    }
}
#endif
