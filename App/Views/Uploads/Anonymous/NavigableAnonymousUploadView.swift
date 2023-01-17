import SwiftUI
import NukeUI

struct NavigableAnonymousUploadView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    @EnvironmentObject private var splitViewModel: SplitViewModel
    
    let anonymousUpload: AnonymousUpload
    
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
    
    private let roundedRectangle = RoundedRectangle(cornerRadius: 8)
    
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
                            .frame(width: 64, height: 64)
                            .redacted(reason: .placeholder)
                    }
                }
                .frame(width: 64, height: 64)
                .clipShape(self.roundedRectangle)
                .overlay {
                    self.roundedRectangle
                        .stroke(.gray)
                }
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
                    Group {
                        if imageAndMetadata.image.lock.isLocked {
                            Text("Locked image")
                        } else {
                            Text(imageAndMetadata.metadataContainer?.data.description ?? "No description")
                        }
                    }
                    .bold()
                } else if let error {
                    Label(error.localizedDescription, systemImage: "exclamationmark.triangle")
                        .foregroundColor(.red)
                        .lineLimit(2)
                }
                Text(self.anonymousUpload.addedOn!, format: .relative(presentation: .numeric))
                    .italic()
                    .font(.subheadline)
            }
            .padding(.leading, 4)
            .padding(.trailing, 4)
        }
        .disabled(!self.isInImages)
        .task {
            if !self.isInImages {
                await self.addImage()
            }
        }
    }
}

#if DEBUG
struct NavigableAnonymousUploadView_Previews: PreviewProvider {
    @StateObject private var coreDataModel = CoreDataModel()
    
    static var previews: some View {
        NavigableAnonymousUploadView(anonymousUpload: AnonymousUpload())
        
    }
}
#endif
