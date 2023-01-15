import SwiftUI
import NukeUI

struct NavigableAnonymousUploadView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    
    let anonymousUpload: AnonymousUpload
    @ObservedObject var splitViewModel: SplitViewModel
    
    @State private var isBusy: Bool = true
    @State private var error: Error?
    
    private var isInImages: Bool {
        return self.splitViewModel.images[self.anonymousUpload.id!] != nil
    }
    
    private func addImage() async {
        self.isBusy = true
        do {
            var imageAndMetadata = IamagesImageAndMetadataContainer(
                image: try await self.globalViewModel.getImagePublicMetadata(id: self.anonymousUpload.id!)
            )
            imageAndMetadata.metadataContainer = try? await self.globalViewModel.getImagePrivateMetadata(for: imageAndMetadata.image)
            self.splitViewModel.images[self.anonymousUpload.id!] = imageAndMetadata
        } catch {
            self.error = error
        }
        self.isBusy = false
    }
    
    var body: some View {
        NavigationLink(value: self.anonymousUpload.id) {
            HStack {
                LazyImage(url: .apiRootUrl.appending(path: "/thumbnails/\(self.anonymousUpload.id!)")) { state in
                    if let image = state.image {
                        image
                            .scaledToFill()
                    } else if state.error != nil {
                        Image(systemName: "exclamationmark.triangle")
                    } else {
                        Rectangle()
                            .redacted(reason: .placeholder)
                    }
                }
                .frame(width: 64, height: 64)
                .cornerRadius(8)
            }
            VStack(alignment: .leading) {
                if self.isBusy {
                    HStack {
                        ProgressView()
                        Text("Loading image...")
                            .foregroundColor(.gray)
                            .padding(.leading, 4)
                    }
                } else if let imageAndMetadata = self.splitViewModel.images[self.anonymousUpload.id!] {
                    if imageAndMetadata.image.lock.isLocked {
                        Text("Locked image")
                    } else {
                        Text(imageAndMetadata.metadataContainer?.data.description ?? "No description")
                    }
                } else if let error {
                    Label(error.localizedDescription, systemImage: "exclamationmark.triangle")
                        .foregroundColor(.red)
                        .lineLimit(2)
                }
                Text(self.anonymousUpload.addedOn!, format: .relative(presentation: .numeric))
                    .italic()
            } 
        }
        .disabled(!self.isInImages)
        .task {
            if !self.isInImages {
                await self.addImage()
            }
        }
    }
}

//#if DEBUG
//struct NavigableAnonymousUploadView_Previews: PreviewProvider {
//    static var previews: some View {
//        NavigableAnonymousUploadView()
//    }
//}
//#endif
