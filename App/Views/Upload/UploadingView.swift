import SwiftUI
import NukeUI

fileprivate struct PendingUploadView: View {
    let pendingUpload: IamagesUploadContainer
    
    var body: some View {
        HStack {
            UniversalDataImage(data: pendingUpload.file.data)
                .frame(width: 64, height: 64)
            VStack(alignment: .leading) {
                Text(pendingUpload.information.description)
                    .bold()
                if pendingUpload.isUploading {
                    ProgressView(value: pendingUpload.progress, total: 100.0)
                } else {
                    if let error: LocalizedError = pendingUpload.error {
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
    
    @Binding var uploadContainers: [IamagesUploadContainer]
    
    @State private var hasBeenViewed: Bool = false

    @State private var isBusy: Bool = true
    @State private var uploaded: [IamagesImage] = []
    
    private func upload() async {
        for i in 0..<self.uploadContainers.count {
            let uploadContainer = self.uploadContainers[i]
            do {
                self.uploadContainers[i].isUploading = true
                self.uploaded.insert(
                    try await self.globalViewModel.uploadImage(for: uploadContainer) { progress in
                        DispatchQueue.main.async {
                            self.uploadContainers[i].progress = progress
                        }
                    },
                    at: 0
                )
                self.uploadContainers.remove(at: i)
            } catch {
                self.uploadContainers[i].isUploading = false
                self.uploadContainers[i].progress = 0.0
                if let error = error as? LocalizedError {
                    self.uploadContainers[i].error = error
                }
                print(error)
            }
        }
        self.isBusy = false
    }
    
    var body: some View {
        List {
            Section("Uploaded") {
                ForEach(self.uploaded) { uploaded in
                    UploadedView(uploaded: uploaded)
                }
            }
            
            Section("Pending") {
                ForEach(self.uploadContainers) { uploadContainer in
                    PendingUploadView(pendingUpload: uploadContainer)
                }
            }
        }
        .navigationTitle("Uploading")
        .navigationBarBackButtonHidden(self.isBusy)
        .task {
            if !self.hasBeenViewed {
                self.hasBeenViewed = true
                await self.upload()
            }
        }
        .toolbar {
            ToolbarItem {
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

#if DEBUG
struct UploadingView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            UploadingView(uploadContainers: .constant([]))
        }
        .environmentObject(GlobalViewModel())
    }
}
#endif
