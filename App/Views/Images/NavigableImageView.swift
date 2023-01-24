import SwiftUI
struct NavigableImageView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel

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
                Group {
                    if self.imageAndMetadata.image.lock.isLocked {
                        Image(systemName: "lock.doc.fill")
                            .font(.title2)
                    } else {
                        ImageThumbnailView(image: self.imageAndMetadata.image)
                    }
                }
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
                        Image(systemName: self.imageAndMetadata.image.contentType == .gif ? "figure.run.square.stack.fill" : "figure.run.square.stack")
                    }
                        
                }
                .padding(.leading, 4)
                .padding(.trailing, 4)
            }
        }
        .contextMenu {
            ImageShareLinkView(image: self.imageAndMetadata.image)
            if self.error != nil {
                Divider()
                Button(action: {
                    Task {
                        await self.getMetadata()
                    }
                }) {
                    Label("Retry loading metadata", systemImage: "arrow.clockwise")
                }
            }
        }
        .task {
            if self.imageAndMetadata.metadataContainer == nil &&
               !self.imageAndMetadata.image.lock.isLocked
            {
                await self.getMetadata()
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
    }
}
#endif
