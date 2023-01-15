import SwiftUI
import NukeUI

struct NavigableImageView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    
    @Binding var imageAndMetadata: IamagesImageAndMetadataContainer

    @State private var isBusy: Bool = true
    @State private var hasAttemptedMetadataLoad: Bool = false
    @State private var error: Error?
    
    private func getMetadata() async {
        self.isBusy = true
        do {
            self.imageAndMetadata.metadataContainer = try await self.globalViewModel.getImagePrivateMetadata(
                for: self.imageAndMetadata.image
            )
        } catch {
            self.error = error
        }
        self.isBusy = false
    }
    
    @ViewBuilder
    private var thumbnail: some View {
        LazyImage(request: self.globalViewModel.getThumbnailRequest(for: self.imageAndMetadata.image)) { state in
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
    
    var body: some View {
        NavigationLink(value: self.imageAndMetadata.image.id) {
            HStack {
                Group {
                    if self.imageAndMetadata.image.lock.isLocked {
                        Image(systemName: "lock.doc.fill")
                            .border(.gray)
                    } else {
                        self.thumbnail
                    }
                }
                .cornerRadius(8)
                .frame(width: 64, height: 64)
                
                VStack(alignment: .leading) {
                    if self.imageAndMetadata.image.lock.isLocked {
                        Text("Locked image")
                            .bold()
                    } else if self.isBusy {
                        LoadingMetadataView()
                    } else {
                        Group {
                            if let error {
                                Text(error.localizedDescription)
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
        }
        .task {
            if !self.hasAttemptedMetadataLoad {
                self.hasAttemptedMetadataLoad = true
                if !self.imageAndMetadata.image.lock.isLocked {
                    await self.getMetadata()
                }
            }
        }
    }
}

#if DEBUG
struct NavigableImageView_Previews: PreviewProvider {
    static var previews: some View {
        NavigableImageView(imageAndMetadata: .constant(previewImageAndMetadata))
    }
}
#endif
