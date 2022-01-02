import SwiftUI
import PhotosUI

/*
 Thanks to:
 - https://github.com/fassko/PHPickerViewController-SwiftUI/blob/main/PHPhotoPickerSwiftUI/PhotoPicker.swift
 - https://github.com/antranapp/AnPhotosPicker/blob/master/Sources/AnPhotosPicker/AnPhotosPicker.swift
 - https://github.com/RemiBardon/swiftui-photos-picker/blob/main/Sources/PhotosPicker/PhotosPicker.swift
 - https://github.com/onizine/PHPickerGetDataSample/blob/main/PHPickerSample/ViewController.swift
 */

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
            if results.isEmpty {
                self.parent.isPresented = false
            }
            
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
