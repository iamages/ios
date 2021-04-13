import SwiftUI
import Kingfisher

// Thanks to Hacking with Swift and Stack Overflow
fileprivate class ImageSaver: NSObject {
    func saveUIImage(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveCb), nil)
    }

    @objc func saveCb(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        var alertTitle: String = ""
        var alertMessage: String = ""
        if let error = error {
            alertTitle = NSLocalizedString("Save error", comment: "")
            alertMessage = error.localizedDescription
        } else {
            alertTitle = NSLocalizedString("Saved file", comment: "")
            alertMessage = NSLocalizedString("Saved the file to your photo library.", comment: "")
        }
        let ac = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: NSLocalizedString("Okay", comment: ""), style: .default))
        let viewController = UIApplication.shared.windows.first!.rootViewController!
        viewController.present(ac, animated: true, completion: nil)
    }
}

struct ImageDetailsScreen: View {
    @EnvironmentObject var dataCentralObservable: IamagesDataCentral
    @Environment(\.presentationMode) var presentationMode

    let file: IamagesFileInformationResponse
    let requestModifier: AnyModifier
    
    @State var newFile: IamagesFileInformationResponse = IamagesFileInformationResponse(JSON: ["FileID": 0, "FileDescription": "", "FileNSFW": false, "FilePrivate": false, "FileMime": "", "FileWidth": 0, "FileHeight": 0, "FileCreatedDate": "", "FileExcludeSearch": false])!
    
    @State var isInfoScreenLinkActive: Bool = false
    @State var isEditScreenLinkActive: Bool = false
    @State var isDeleteScreenLinkPresented: Bool = false
    
    @State var isPopBackToRoot: Bool = false
    
    private let imageSaver = ImageSaver()

    var body: some View {
        if self.isPopBackToRoot {
            VStack(alignment: .center) {
                Image(systemName: "pencil")
                    .font(.largeTitle)
                    .padding(.vertical)
                Text("File edited/deleted")
                    .font(.title2)
                    .bold()
                    .padding(.bottom)
                Text("Tap another file on the side to view it.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
            }.padding(.all)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    EmptyView()
                }
            }.onAppear {
                self.presentationMode.wrappedValue.dismiss()
            }
        } else {
            ZoomableScrollComponent {
                KFImage(api.get_root_img(id: file.id))
                    .requestModifier(requestModifier)
                    .resizable()
                    .loadImmediately()
                    .placeholder {
                        ProgressView().progressViewStyle(CircularProgressViewStyle())
                    }
                    .scaledToFit()
            }.toolbar {
                ToolbarItem(placement: .principal) {
                    Button(action: {
                        self.isInfoScreenLinkActive = true
                    }) {
                        Image(systemName: "info.circle")
                            .imageScale(.large)
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Section {
                            Button(action: {
                                self.openShareSheet()
                            }) {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                            Button(action: {
                                self.saveImageToPhotoLibrary()
                            }) {
                                Label("Save to library", systemImage: "square.and.arrow.down")
                            }
                            Button(action: {
                                self.openMailReportContent()
                            }) {
                                Label("Report file", systemImage: "exclamationmark.bubble")
                            }
                        }
                        Section {
                            if dataCentralObservable.checkEditable(id: file.id) {
                                Button(action: {
                                    self.isEditScreenLinkActive = true
                                }) {
                                    Label("Edit file", systemImage: "pencil")
                                }
                                Button(action: {
                                    self.isDeleteScreenLinkPresented = true
                                }) {
                                    Label("Delete file", systemImage: "trash")
                                }
                            }
                        }
                    }
                    label: {
                        Image(systemName: "ellipsis.circle")
                            .imageScale(.large)
                    }
                }
            }.onAppear {
                self.newFile = file
            }
            .background(
                NavigationLink(destination: FullInformationScreen(newFile: self.$newFile), isActive: self.$isInfoScreenLinkActive) {
                    EmptyView()
                }
            ).background(
                NavigationLink(destination: ImageDetailsEditInformationScreen(file: self.file, newFile: self.$newFile, isPopBackToRoot: self.$isPopBackToRoot), isActive: self.$isEditScreenLinkActive) {
                    EmptyView()
                }
            )
            .background(
                NavigationLink(destination: DeleteFileScreen(newFile: self.$newFile, isPopBackToRoot: self.$isPopBackToRoot), isActive: self.$isDeleteScreenLinkPresented) {
                    EmptyView()
                }
            )
        }
    }
    
    // Thanks to Roland Lariotte on Stack Overflow for this smart solution! Apple,
    // we need a simpler way to open your share menu!
    func openShareSheet() {
        guard let source = UIApplication.shared.windows.last?.rootViewController else {
            return
        }

        let activityVC = UIActivityViewController(activityItems: [api.get_root_embed(id: self.file.id)], applicationActivities: nil)

        if let popoverController = activityVC.popoverPresentationController {
          popoverController.sourceView = source.view
          popoverController.sourceRect = CGRect(x: source.view.bounds.midX,
                                                y: source.view.bounds.midY,
                                                width: .zero, height: .zero)
          popoverController.permittedArrowDirections = []
        }
        source.present(activityVC, animated: true)
    }
    
    func saveImageToPhotoLibrary() {
        KingfisherManager.shared.retrieveImage(with: api.get_root_img(id: self.file.id)) { result in
            let image = try? result.get().image
            if let image = image {
                self.imageSaver.saveUIImage(image: image)
            }
        }
    }
    
    func openMailReportContent() {
        UIApplication.shared.open(URL(string: "mailto:iamages@uber.space?subject=Report%20Content%20on%20Iamages&body=FileID%3A%20\(self.file.id)%0AReason%3A%20Input%20report%20reason%20here.")!)
    }
}

struct ImageDetailScreen_Previews: PreviewProvider {
    static var previews: some View {
        ImageDetailsScreen(file: IamagesFileInformationResponse(JSON: ["FileID": 1, "FileDescription": "Test File", "FileNSFW": false, "FilePrivate": false, "FileMime": "image/jpeg", "FileWidth": 696, "FileHeight": 696, "FileCreatedDate": "2020-12-14 14:40:52"])!, requestModifier: AnyModifier(modify: { request in
                return request
            }))
    }
}
