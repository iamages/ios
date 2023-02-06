import SwiftUI
struct NavigableImageView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    @EnvironmentObject private var splitViewModel: SplitViewModel

    @Binding var imageAndMetadata: IamagesImageAndMetadataContainer

    @State private var error: Error?
    
    private func getMetadata() async {
        self.error = nil
        self.imageAndMetadata.isLoading = true
        do {
            let metadata = try await self.globalViewModel.getImagePrivateMetadata(
                for: self.imageAndMetadata.image
            )
            withAnimation {
                self.imageAndMetadata.metadataContainer = metadata
            }
        } catch {
            self.error = error
        }
        self.imageAndMetadata.isLoading = false
    }

    private let roundedRectangle = RoundedRectangle(cornerRadius: 8)
    
    var body: some View {
        NavigationLink(value: self.imageAndMetadata.id) {
            HStack {
                ImageThumbnailView(image: self.imageAndMetadata.image)
                    .frame(width: 64, height: 64)
                    .clipShape(self.roundedRectangle)
                    .overlay {
                        self.roundedRectangle
                            .stroke(.gray)
                    }
                
                VStack(alignment: .leading) {
                    if self.imageAndMetadata.image.lock.isLocked {
                        Text("Locked image")
                            .bold()
                    } else if self.imageAndMetadata.isLoading {
                        LoadingMetadataView()
                    } else {
                        Group {
                            if let error {
                                Label(error.localizedDescription, systemImage: "exclamationmark.triangle")
                                    .foregroundColor(.red)
                            } else if let metadata = self.imageAndMetadata.metadataContainer?.data {
                                Text(verbatim: metadata.description)
                            }
                        }
                        .bold()
                        .lineLimit(1)
                    }
                    HStack {
                        Image(systemName: self.imageAndMetadata.image.isPrivate ? "eye.slash.fill" : "eye.slash")
                        Image(systemName: self.imageAndMetadata.image.file.contentType == .gif ? "figure.run.square.stack.fill" : "figure.run.square.stack")
                    }
                        
                }
                .padding(.leading, 4)
                .padding(.trailing, 4)
            }
        }
        .contextMenu {
            if self.error != nil {
                Button(action: {
                    Task {
                        await self.getMetadata()
                    }
                }) {
                    Label("Retry loading metadata", systemImage: "arrow.clockwise")
                }
                Divider()
            }
            ImageShareLinkView(image: self.imageAndMetadata.image)
            Divider()
            if self.imageAndMetadata.image.owner == self.globalViewModel.userInformation?.username {
                Button(role: .destructive, action: {
                    self.splitViewModel.imageToDelete = self.imageAndMetadata
                }) {
                    Label("Delete image", systemImage: "trash")
                }
            }
        }
        .task {
            if self.imageAndMetadata.metadataContainer == nil &&
               !self.imageAndMetadata.image.lock.isLocked
            {
                await self.getMetadata()
            } else {
                self.imageAndMetadata.isLoading = false
            }
        }
    }
}

#if DEBUG
struct NavigableImageView_Previews: PreviewProvider {
    static var previews: some View {
        NavigableImageView(
            imageAndMetadata: .constant(previewImageAndMetadata)
        )
        .environmentObject(GlobalViewModel())
        .environmentObject(SplitViewModel())
    }
}
#endif
