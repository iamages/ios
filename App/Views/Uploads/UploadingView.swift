import SwiftUI
import NukeUI

struct UploadingView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    @EnvironmentObject private var uploadsViewModel: UploadsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var completedUploads: [IamagesImage] = []
    
    @State private var isCancelUploadsAlertPresented: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading) {
                    if let collection = self.uploadsViewModel.collection {
                        Text("Collection")
                            .bold()
                            .foregroundColor(.gray)
                        UploadCollectionView(
                            collection: collection,
                            completedUploads: self.completedUploads
                        )
                        Divider()
                    }
                    Text("Uploaded")
                        .bold()
                        .foregroundColor(.gray)
                    ScrollView(.horizontal) {
                        LazyHGrid(rows: [GridItem(.fixed(64), spacing: 4)]) {
                            ForEach(self.completedUploads) { completedUpload in
                                CompletedUploadView(image: completedUpload)
                            }
                            if self.uploadsViewModel.uploadContainers.count - self.completedUploads.count > 0 {
                                ForEach((1...(self.uploadsViewModel.uploadContainers.count-self.completedUploads.count)).reversed(), id: \.self) { _ in
                                    Rectangle()
                                        .fill(.gray)
                                        .redacted(reason: .placeholder)
                                        .frame(width: 64, height: 64)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    if !self.uploadsViewModel.uploadContainers.isEmpty {
                        Divider()
                        Text("Uploading")
                            .bold()
                            .foregroundColor(.gray)
                        ForEach(self.uploadsViewModel.uploadContainers) { uploadContainer in
                            PendingUploadView(
                                uploadContainer: uploadContainer,
                                collectionID: self.uploadsViewModel.collection?.id,
                                completedUploads: self.$completedUploads
                            )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Uploading")
            .navigationBarTitleDisplayMode(.inline)
            #if targetEnvironment(macCatalyst)
            .withHostingWindow { window in
                window?.windowScene?.windowingBehaviors?.isClosable = false
            }
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        if self.uploadsViewModel.uploadContainers.isEmpty {
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
        UploadingView()
            .environmentObject(GlobalViewModel())
            .environmentObject(UploadsViewModel())
    }
}
#endif
