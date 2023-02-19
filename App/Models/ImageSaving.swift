import SwiftUI
import UniformTypeIdentifiers

struct SavedImageDocument: FileDocument {
    static var readableContentTypes: [UTType] = [.jpeg, .png, .webP, .gif]
    
    var data: Data
    
    init(data: Data) {
        self.data = data
    }
    
    init(configuration: ReadConfiguration) throws {
        fatalError("SavedImageDocument read not available.")
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: self.data)
    }
}

class ImageSaver: NSObject {
    static func writeToPhotoAlbum(data: Data) {
        guard let image = UIImage(data: data) else {
            return
        }
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveCompleted), nil)
    }
    
    // FIXME: Hacky alert presentation.
    @objc
    static func saveCompleted(
        _ image: UIImage,
        didFinishSavingWithError error: Error?,
        contextInfo: UnsafeRawPointer
    ) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return
        }
        var alert: UIAlertController
        if let error {
            alert = UIAlertController(
                title: "Couldn't save image",
                message: error.localizedDescription,
                preferredStyle: .alert
            )
        } else {
            alert = UIAlertController(
                title: "Image downloaded",
                message: "The image has been saved to your photos library",
                preferredStyle: .alert
            )
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        window.rootViewController?.present(alert, animated: true)
    }
}
