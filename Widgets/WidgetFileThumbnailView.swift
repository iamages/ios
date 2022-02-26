import SwiftUI
import WidgetKit

struct WidgetFileThumbnailView: View {
    @AppStorage("isNSFWEnabled", store: UserDefaults(suiteName: "group.me.jkelol111.Iamages")) var isNSFWEnabled: Bool = true
    @AppStorage("isNSFWBlurred", store: UserDefaults(suiteName: "group.me.jkelol111.Iamages")) var isNSFWBlurred: Bool = true

    let file: IamagesFile?
    let thumb: Data?
    
    var nsfwLabel: some View {
        Image(systemName: "18.circle")
            .font(.largeTitle)
            .privacySensitive(false)
    }
    
    var body: some View {
        if let file = self.file {
            if file.isNSFW && !self.isNSFWEnabled {
                self.nsfwLabel
            } else {
                Link(destination: URL(string: "iamages://view?type=file&id=\(file.id)")!) {
                    if let thumb = self.thumb {
                        if file.isNSFW && self.isNSFWBlurred {
                            Image(uiImage: UIImage(data: thumb)!)
                                .resizable()
                                .scaledToFill()
                                .blur(radius: 12.0)
                                .overlay {
                                    self.nsfwLabel
                                }
                        } else {
                            Image(uiImage: UIImage(data: thumb)!)
                                .resizable()
                                .scaledToFill()
                        }
                    } else {
                        Image(systemName: "questionmark.app.dashed")
                            .font(.largeTitle)
                    }
                }
            }
        } else {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .privacySensitive(false)
        }
    }
}
