import SwiftUI
import PhotosUI

// Thanks to: prafullakumar on GitHub
struct PhotoPickerComponent: UIViewControllerRepresentable {
    let configuration: PHPickerConfiguration
    @Binding var pickerResultInformation: [IamagesUploadRequest]
    @Binding var isPhotosPickerPresented: Bool

    func makeUIViewController(context: Context) -> PHPickerViewController {
        let controller = PHPickerViewController(configuration: configuration)
        controller.delegate = context.coordinator
        return controller
    }
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) { }
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: PHPickerViewControllerDelegate {
        private let parent: PhotoPickerComponent
        
        init(_ parent: PhotoPickerComponent) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            for image in results {
                if image.itemProvider.canLoadObject(ofClass: UIImage.self)  {
                    image.itemProvider.loadObject(ofClass: UIImage.self) { (object, error) in
                        if let error = error {
                            print("Could not add photo, error: " + error.localizedDescription)
                        } else {
                            if let newImage = object as? UIImage {
                                self.parent.pickerResultInformation.append(IamagesUploadRequest(description: NSLocalizedString("No description yet.", comment: ""), isNSFW: false, isPrivate: false, img: newImage))
                            } else {
                                print("Could not convert an image into UIImage.")
                            }
                            print(self.parent.pickerResultInformation)
                        }
                    }
                } else {
                    print("Loaded Asset is not a Image!")
                }
            }
            parent.isPhotosPickerPresented = false
        }
    }
}
