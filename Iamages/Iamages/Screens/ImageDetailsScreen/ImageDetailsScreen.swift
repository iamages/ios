import SwiftUI
import KingfisherSwiftUI
import class Kingfisher.KingfisherManager
import struct Kingfisher.AnyModifier

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
    
    @State var newFile: IamagesFileInformationResponse = IamagesFileInformationResponse(JSON: ["FileID": 0, "FileDescription": "", "FileNSFW": false, "FilePrivate": false, "FileMime": "", "FileWidth": 0, "FileHeight": 0, "FileCreatedDate": ""])!
    
    @State var isInfoScreenLinkActive: Bool = false
    @State var isEditScreenLinkActive: Bool = false
    @State var isDeleteScreenLinkPresented: Bool = false
    
    @State var isPopBackToRoot: Bool = false
    
    private let imageSaver = ImageSaver()

    var body: some View {
        ZoomableScrollComponent {
            KFImage(api.get_root_img(id: file.id), options: [.requestModifier(requestModifier)])
                .resizable()
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
        }.onAppear() {
            if self.isPopBackToRoot {
                self.presentationMode.wrappedValue.dismiss()
            }
            self.newFile = self.file
        }.background(
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
    
    func openShareSheet() {
        let av = UIActivityViewController(activityItems: [api.get_root_embed(id: self.file.id)], applicationActivities: nil)
        UIApplication.shared.windows.first?.rootViewController?.present(av, animated: true, completion: nil)
    }
    
    func saveImageToPhotoLibrary() {
        KingfisherManager.shared.retrieveImage(with: api.get_root_img(id: file.id)) { result in
            let image = try? result.get().image
            if let image = image {
                self.imageSaver.saveUIImage(image: image)
            }
        }
    }
}

struct ImageDetailScreen_Previews: PreviewProvider {
    static var previews: some View {
        ImageDetailsScreen(file: IamagesFileInformationResponse(JSON: ["FileID": 1, "FileDescription": "Test File", "FileNSFW": false, "FilePrivate": false, "FileMime": "image/jpeg", "FileWidth": 696, "FileHeight": 696, "FileCreatedDate": "2020-12-14 14:40:52"])!, requestModifier: AnyModifier(modify: { request in
                return request
            }))
    }
}
