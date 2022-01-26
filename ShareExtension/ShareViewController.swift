import UIKit
import Social
import UniformTypeIdentifiers
import KeychainSwift

fileprivate enum ShareErrors: Error {
    case fileTooBig(Int)
}

extension ShareErrors: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .fileTooBig(let size):
            return NSLocalizedString("Photo file size is larger than 50Mb (\(size))", comment: "")
        }
    }
}

class ShareViewController: SLComposeServiceViewController {
    private var uploadRequest: UploadFileRequest = UploadFileRequest(info: UploadJSONRequest(description: "", isNSFW: false, isPrivate: false, isHidden: false, url: nil), file: nil)
    
    override func viewDidLoad() {
        let navigationBar = self.navigationController?.navigationBar
        navigationBar?.tintColor = .systemOrange
        for item in (navigationBar?.items)! {
            if let rightItem = item.rightBarButtonItem {
                rightItem.title = "Upload"
                break
            }
        }

        let provider: NSItemProvider = (self.extensionContext!.inputItems.first as! NSExtensionItem).attachments!.first!
        if let identifier = provider.registeredTypeIdentifiers.first {
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadDataRepresentation(forTypeIdentifier: identifier) { data, error in
                    if let data = data {
                        if data.count < 50000000 {
                            self.uploadRequest.file = UploadFile(image: data, type: UTType(identifier)!)
                        } else {
                            self.extensionContext!.cancelRequest(withError: ShareErrors.fileTooBig(data.count))
                        }
                    } else if let error = error {
                        self.extensionContext!.cancelRequest(withError: error)
                    }
                }
            }
        }
    }
    
    override func isContentValid() -> Bool {
        if self.contentText.isEmpty {
            return false
        }
        return true
    }

    override func didSelectPost() {
        #if DEBUG
        let apiRoot: String = "http://localhost:9999/iamages/api/v3"
        #else
        let apiRoot: String = "https://iamages.uber.space/iamages/api/v3"
        #endif
        let keychain = KeychainSwift(keyPrefix: "iamages_")
        keychain.accessGroup = "group.me.jkelol111.Iamages"
        
        self.uploadRequest.info.description = self.contentText

        var request = URLRequest(url: URL(string: "\(apiRoot)/file/new/upload")!)
        request.httpMethod = "POST"
        if let username = keychain.get("username"), let password = keychain.get("password") {
            request.addValue("Basic " + "\(username):\(password)".data(using: .utf8)!.base64EncodedString(), forHTTPHeaderField: "Authorization")
        }
        request.addValue("multipart/form-data; charset=utf-8; boundary=iamages", forHTTPHeaderField: "Content-Type")
        
        var body: Data = Data()
        body.append("\r\n--iamages\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"info\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/json\r\n\r\n".data(using: .utf8)!)
        do {
            body.append(try JSONEncoder().encode(self.uploadRequest.info))
        } catch {
            self.extensionContext!.cancelRequest(withError: error)
        }
        body.append("\r\n--iamages\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"upload_file\"; filename=\"\(UUID().uuidString).\(self.uploadRequest.file!.type.preferredFilenameExtension!)\" \r\n".data(using: .utf8)!)
        body.append("Content-Type: \(self.uploadRequest.file!.type.preferredMIMEType!)\r\n\r\n".data(using: .utf8)!)
        body.append(self.uploadRequest.file!.image)
        body.append("\r\n--iamages--\r\n".data(using: .utf8)!)

        URLSession.shared.uploadTask(with: request, from: body)
            .resume()

        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }

    override func configurationItems() -> [Any]! {
        var isNSFWConfigurationItem: SLComposeSheetConfigurationItem {
            let item = SLComposeSheetConfigurationItem()!
            item.title = "NSFW"
            item.value = "No"
            item.tapHandler = {
                self.uploadRequest.info.isNSFW.toggle()
                item.value = self.uploadRequest.info.isNSFW ? "Yes" : "No"
            }
            return item
        }
        var isPrivateConfigurationItem: SLComposeSheetConfigurationItem {
            let item = SLComposeSheetConfigurationItem()!
            item.title = "Private"
            item.value = "No"
            item.tapHandler = {
                self.uploadRequest.info.isPrivate.toggle()
                item.value = self.uploadRequest.info.isPrivate ? "Yes" : "No"
            }
            return item
        }
        var isHiddenConfigurationItem: SLComposeSheetConfigurationItem {
            let item = SLComposeSheetConfigurationItem()!
            item.title = "Hidden"
            item.value = "No"
            item.tapHandler = {
                self.uploadRequest.info.isHidden.toggle()
                item.value = self.uploadRequest.info.isHidden ? "Yes" : "No"
            }
            return item
        }
        return [
            isNSFWConfigurationItem,
            isPrivateConfigurationItem,
            isHiddenConfigurationItem
        ]
    }

}
