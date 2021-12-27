import SwiftUI

struct UploadingView: View {
    @EnvironmentObject var dataObservable: APIDataObservable
    
    @Binding var uploadRequests: [UploadFileRequest]
    @Binding var isPresented: Bool
    
    @State var isBusy: Bool = false
    @State var uploadedFiles: [IamagesFile] = []
    
    func upload (uploadRequest: UploadFileRequest) async {
        self.isBusy = true
        do {
            self.uploadedFiles.append(try await self.dataObservable.upload(request: uploadRequest))
            if let position = self.uploadRequests.firstIndex(of: uploadRequest) {
                self.uploadRequests.remove(at: position)
            }
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
                                Label(title: {
                                    Text(verbatim: self.dataObservable.currentAppUser?.username ?? "Anonymous")
                                        .bold()
                                        .lineLimit(1)
                                }, icon: {
                                    ProfileImageView(username: self.dataObservable.currentAppUser?.username)
                                })
                                FileThumbnailView(id: uploadedFile.id)
                                Text(uploadedFile.description)
                            }
                            .padding(.top, 4)
                            .padding(.bottom, 4)
                        }
                    }
                }
                Section(self.isBusy ? "Uploading" : "Failed") {
                    ForEach(self.uploadRequests) { uploadRequest in
                        VStack(alignment: .leading) {
                            Label(title: {
                                Text(verbatim: self.dataObservable.currentAppUser?.username ?? "Anonymous")
                                    .bold()
                                    .lineLimit(1)
                            }, icon: {
                                ProfileImageView(username: self.dataObservable.currentAppUser?.username)
                            })
                            if uploadRequest.file != nil {
                                Image(uiImage: UIImage(data: uploadRequest.file!.image)!)
                                    .resizable()
                                    .scaledToFit()
                            } else {
                                Label(uploadRequest.info.url!.absoluteString, systemImage: "globe")
                                    .lineLimit(1)
                            }
                            Text(uploadRequest.info.description)
                        }
                        .padding(.top, 4)
                        .padding(.bottom, 4)
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
            .navigationTitle(self.isBusy ? "Uploading" : "Uploaded")
        }
        .interactiveDismissDisabled(self.isBusy)
    }
}
