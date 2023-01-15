import SwiftUI

struct PendingUploadView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    let uploadContainer: IamagesUploadContainer
    
    @StateObject var model: UploadViewModel = UploadViewModel()
    
    private func upload() async {
        await self.model.upload()
        if self.model.error == nil {
            NotificationCenter.default.post(name: .deleteUpload, object: self.uploadContainer.id)
        }
    }

    var body: some View {
        HStack {
            UniversalDataImage(data: uploadContainer.file.data)
                .frame(width: 64, height: 64)
            VStack(alignment: .leading) {
                Text(uploadContainer.information.description)
                    .bold()
                if self.model.isUploading {
                    ProgressView(value: self.model.progress, total: 100.0)
                } else {
                    if let error = self.model.error {
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
        .task {
            self.model.viewContext = self.viewContext
            self.model.information = self.uploadContainer.information
            self.model.file = self.uploadContainer.file
            await self.upload()
        }
        .onReceive(NotificationCenter.default.publisher(for: .retryUploads)) { _ in
            Task {
                await self.upload()
            }
        }
    }
}

#if DEBUG
struct PendingUploadView_Previews: PreviewProvider {
    static var previews: some View {
        PendingUploadView(uploadContainer: previewUploadContainer)
    }
}
#endif
