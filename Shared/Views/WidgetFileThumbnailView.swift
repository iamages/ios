import SwiftUI

struct WidgetFileThumbnailView: View {
    @AppStorage("isNSFWEnabled", store: UserDefaults(suiteName: "group.me.jkelol111.Iamages")) var isNSFWEnabled: Bool = true
    @AppStorage("isNSFWBlurred", store: UserDefaults(suiteName: "group.me.jkelol111.Iamages")) var isNSFWBlurred: Bool = true

    let file: IamagesFile?
    let thumb: Data?
    
    var nsfwLabel: some View {
        Image(systemName: "18.circle")
            .font(.largeTitle)
            .foregroundColor(.white)
    }
    
    var body: some View {
        if let file = self.file {
            if file.isNSFW && !self.isNSFWEnabled {
                self.nsfwLabel
                    .widgetURL(URL(string: "iamages://feed")!)
            } else {
                Group {
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
                            .imageScale(.large)
                    }
                }
                .widgetURL(URL(string: "iamages://view?type=file&id=\(file.id)"))
            }
        } else {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .widgetURL(URL(string: "iamages://feed")!)
        }
    }
}
