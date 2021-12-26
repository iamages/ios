import SwiftUI

struct UploadingView: View {
    @EnvironmentObject var dataObservable: APIDataObservable
    
    @Binding var uploadRequests: [UploadFileRequest]
    @Binding var isPresented: Bool
    
    @State var isBusy: Bool = false
    @State var uploadedFiles: [IamagesFile] = []
    @State var uploadFailed: [UploadFailedInfo] = []
    
    func upload (uploadRequest: UploadFileRequest) async {
        self.isBusy = true
        do {
            self.uploadedFiles.append(try await self.dataObservable.upload(request: uploadRequest))
        } catch {
            print(error)
        }
        self.isBusy = false
    }
    
    var body: some View {
        NavigationView {
            List {
                Section("Uploaded") {
                    ForEach(self.uploadedFiles) { uploadedFile in
                        Link(destination: self.dataObservable.getFileEmbedURL(id: uploadedFile.id)) {
                            VStack(alignment: .leading) {
                                 
                            }
                        }
                    }
                }
                Section(self.isBusy ? "Uploading" : "Failed") {
                    ForEach(self.uploadRequests) { uploadRequest in
                        
                    }
                }
            }
            .task {
                if !self.isBusy {
                    for uploadRequest in uploadRequests {
                        await self.upload(uploadRequest: uploadRequest)
                    }
                }
            }
            .toolbar {
                ToolbarItem {
                    if self.isBusy {
                        ProgressView()
                    } else {
                        Button(action: {
                            self.isPresented = false
                        }) {
                            Label("Close", systemImage: "xmark")
                        }
                    }
                }
            }
            .navigationTitle("Uploading")
        }
        .interactiveDismissDisabled(self.isBusy)
    }
}
