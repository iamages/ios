import SwiftUI
import PhotosUI

struct PhotosPickerView: UIViewControllerRepresentable {
    let imageRetrievedHandler: (Data, String) -> Void
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = 0
        configuration.selection = .ordered
        
        let controller = PHPickerViewController(configuration: configuration)
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) { }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: PHPickerViewControllerDelegate {
        private let parent: PhotosPickerView
        
        init(_ parent: PhotosPickerView) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            let pickerResultLength: Int = results.count
            var pickedCount: Int = 0 {
                didSet {
                    if pickedCount == pickerResultLength {
                        self.parent.isPresented = false
                    }
                }
            }
            
            results.forEach { image in
                let provider = image.itemProvider
                if let typeIdentifier: String = provider.registeredTypeIdentifiers.first {
                    if provider.canLoadObject(ofClass: UIImage.self) {
                        provider.loadDataRepresentation(forTypeIdentifier: typeIdentifier, completionHandler: { data, error in
                            if let data = data {
                                self.parent.imageRetrievedHandler(data, typeIdentifier)
                            } else if let error = error {
                                print(error)
                            }
                            pickedCount += 1
                        })
                    }
                }
            }
        }
    }
}
