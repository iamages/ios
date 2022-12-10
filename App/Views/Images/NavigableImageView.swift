import SwiftUI
import NukeUI

struct NavigableImageView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    
    @Binding var image: IamagesImage
    
    @State private var metadata: IamagesImageMetadata?
    @State private var isBusy: Bool = true
    @State private var hasAttemptedMetadataLoad: Bool = false
    @State private var error: Error?
    
    var body: some View {
        NavigationLink(value: self.image) {
            HStack {
                Group {
                    if self.image.lock.isLocked {
                        Image(systemName: "lock.doc.fill")
                    } else {
                        LazyImage(request: self.globalViewModel.getThumbnailRequest(for: self.image)) { state in
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
                        .animation(nil)
                    }
                }
                .cornerRadius(8)
                .frame(width: 64, height: 64)
                
                VStack(alignment: .leading) {
                    if self.image.lock.isLocked {
                        Text("Locked image")
                            .bold()
                    } else if self.isBusy {
                        LoadingMetadataView()
                    } else {
                        Group {
                            if let error {
                                Text(error.localizedDescription)
                                    .foregroundColor(.red)
                            } else if let metadata {
                                Text(verbatim: metadata.description)
                            }
                        }
                        .bold()
                        .lineLimit(1)
                    }
                    HStack {
                        Image(systemName: self.image.isPrivate ? "eye.slash.fill" : "eye.slash")
                        Image(systemName: self.image.lock.isLocked ? "lock.doc.fill" : "lock.doc")
                        Image(systemName: self.image.contentType == .gif ? "figure.run.square.stack.fill" : "figure.run.square.stack")
                    }
                        
                }
                .padding(.leading, 4)
                .padding(.trailing, 4)
            }
        }
        .task {
            if !self.hasAttemptedMetadataLoad {
                self.hasAttemptedMetadataLoad = true
                if !self.image.lock.isLocked {
                    do {
                        self.metadata = try await self.globalViewModel.getImagePrivateMetadata(for: self.image)
                    } catch {
                        self.error = error
                        print(error)
                    }
                }
                self.isBusy = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .editImage)) { output in
            if let notification = output.object as? EditImageNotification,
               notification.id == self.image.id,
               notification.edit.change == .description {
                switch notification.edit.to {
                case .string(let description):
                    self.metadata?.description = description
                default:
                    break
                }
            }
        }
    }
}

#if DEBUG
struct NavigableImageView_Previews: PreviewProvider {
    static var previews: some View {
        NavigableImageView(image: .constant(previewImage))
    }
}
#endif
