import SwiftUI
import NukeUI
import OrderedCollections

struct UploadingView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    @Environment(\.dismiss) private var dismiss

    @Binding var uploadContainers: OrderedDictionary<UUID, IamagesUploadContainer>

    @State private var isBusy: Bool = true
    @State private var uploaded: [IamagesImage] = []
    
    var body: some View {
        NavigationStack {
            List {
                Section("Uploaded") {
                    ForEach(self.uploaded) { uploaded in
                        UploadedView(uploaded: uploaded)
                    }
                }
                
                Section("Pending") {
                    ForEach(self.uploadContainers.values) { uploadContainer in
                        PendingUploadView(uploadContainer: uploadContainer)
                    }
                }
            }
            .navigationTitle("Uploading")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        self.dismiss()
                    }) {
                        Label("Close", systemImage: "xmark")
                    }
                    .disabled(self.isBusy)
                }
                ToolbarItem(placement: .primaryAction) {
                    if !self.uploadContainers.isEmpty && !self.isBusy {
                        Button(action: {
                            NotificationCenter.default.post(name: .retryUploads, object: nil)
                        }) {
                            Label("Retry failed uploads", systemImage: "exclamationmark.arrow.triangle.2.circlepath")
                        }
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
