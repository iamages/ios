import SwiftUI
import NukeUI
import OrderedCollections

fileprivate struct PendingUploadView: View {
    let uploadContainer: IamagesUploadContainer
    @Binding var errors: [UUID: LocalizedError]
    
    var body: some View {
        HStack {
            UniversalDataImage(data: uploadContainer.file.data)
                .frame(width: 64, height: 64)
            VStack(alignment: .leading) {
                Text(uploadContainer.information.description)
                    .bold()
                if uploadContainer.isUploading {
                    ProgressView(value: uploadContainer.progress, total: 100.0)
                } else {
                    if let error = errors[uploadContainer.id] {
                        Text(error.localizedDescription)
                            .foregroundColor(.red)
                        if let recoverySuggestion: String = error.recoverySuggestion {
                            Text(recoverySuggestion)
                        }
                    } else {
                        ProgressView()
                    }
                }
            }
            .padding(.leading, 4)
            .padding(.trailing, 4)
        }
        
    }
}

fileprivate struct UploadedView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    
    let uploaded: IamagesImage
    
    var body: some View {
        if !uploaded.lock.isLocked {
            Image(systemName: "lock.fill")
        } else {
            LazyImage(request: self.globalViewModel.getThumbnailRequest(for: self.uploaded)) { state in
                if let image = state.image {
                    image
                        .resizingMode(.aspectFill)
                } else if state.error != nil {
                    Image(systemName: "exclamationmark.octagon.fill")
                } else {
                    Rectangle()
                        .redacted(reason: .placeholder)
                }
            }
        }
    }
}

struct UploadingView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    @Environment(\.dismiss) private var dismiss

    @Binding var uploadContainers: OrderedDictionary<UUID, IamagesUploadContainer>
    
    @State private var hasBeenViewed: Bool = false

    @State private var isBusy: Bool = true
    @State private var uploaded: [IamagesImage] = []
    @State private var errors: [UUID: LocalizedError] = [:]

    private func upload() async {
        for id in self.uploadContainers.keys {
            do {
                self.uploadContainers[id]?.isUploading = true
                guard let container = self.uploadContainers[id] else { continue }
                self.uploaded.insert(
                    try await self.globalViewModel.uploadImage(for: container) { progress in
                        DispatchQueue.main.sync {
                            self.uploadContainers[id]?.progress = progress
                        }
                    },
                    at: 0
                )
                self.uploadContainers.removeValue(forKey: id)
            } catch {
                self.uploadContainers[id]?.isUploading = false
                self.uploadContainers[id]?.progress = 0.0
                if let error = error as? LocalizedError {
                    self.errors[id] = error
                }
            }
        }
        self.isBusy = false
    }
    
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
                        PendingUploadView(
                            uploadContainer: uploadContainer,
                            errors: self.$errors
                        )
                    }
                }
            }
            .navigationTitle("Uploading")
            .task {
                if !self.hasBeenViewed {
                    self.hasBeenViewed = true
                    await self.upload()
                }
            }
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
                    Button(action: {
                        Task {
                            await self.upload()
                        }
                    }) {
                        Label("Retry failed uploads", systemImage: "exclamationmark.arrow.triangle.2.circlepath")
                    }
                    .disabled(self.isBusy)
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
