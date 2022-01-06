import SwiftUI

enum UploadMode {
    case separate
    case toCollection
}

struct UploadingFilesListView: View {
    @EnvironmentObject var dataObservable: APIDataObservable

    @Binding var uploadRequests: [UploadFileRequest]
    @Binding var mode: UploadMode
    @Binding var newCollection: NewCollectionRequest
    @Binding var isPresented: Bool
    
    @State var isBusy: Bool = false
    @State var uploadedFiles: [IamagesFile] = []
    @State var createdCollection: IamagesCollection?
    
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
    
    var pfp: some View {
        Label(title: {
            Text(verbatim: self.dataObservable.currentAppUser?.username ?? "Anonymous")
                .bold()
                .lineLimit(1)
        }, icon: {
            ProfileImageView(username: self.dataObservable.currentAppUser?.username)
        })
    }

    var body: some View {
        NavigationView {
            List {
                if self.createdCollection != nil {
                    Section("Collection") {
                        Link(destination: self.dataObservable.getCollectionEmbedURL(id: self.createdCollection!.id)) {
                            VStack(alignment: .leading) {
                                self.pfp
                                LazyVGrid(columns: [GridItem(), GridItem()]) {
                                    ForEach(self.uploadedFiles.prefix(4)) { file in
                                        FileThumbnailView(id: file.id)
                                    }
                                }
                                Text(verbatim: self.createdCollection!.description)
                                    .lineLimit(1)
                            }
                            .padding(.top, 4)
                            .padding(.bottom, 4)
                        }
                    }
                }
                Section("Uploaded") {
                    ForEach(self.uploadedFiles) { uploadedFile in
                        Link(destination: self.dataObservable.getFileEmbedURL(id: uploadedFile.id)) {
                            VStack(alignment: .leading) {
                                self.pfp
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
                            self.pfp
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
                if !self.isBusy && !self.uploadRequests.isEmpty {
                    for uploadRequest in uploadRequests {
                        await self.upload(uploadRequest: uploadRequest)
                    }
                    if self.mode == .toCollection {
                        self.isBusy = true
                        do {
                            self.newCollection.fileIDs = self.uploadedFiles.map { $0.id }
                            self.createdCollection = try await self.dataObservable.newCollection(request: self.newCollection)
                        } catch {
                            print(error)
                        }
                        // Reset newCollection for future toCollection uploads.
                        self.newCollection = NewCollectionRequest(description: "No description yet.", isPrivate: false, isHidden: false)
                        self.isBusy = false
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
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled(self.isBusy)
        }
    }
}
