import SwiftUI
import class Kingfisher.ImageCache

struct AppSettingsScreen: View {
    @AppStorage("NSFWEnabled") var isNSFWEnabled: Bool = false
    @AppStorage("NSFWBlurred") var isNSFWBlurred: Bool = true
    @AppStorage("PreferredUploadFormat") var preferredUploadFormat: String = "png"
    @AppStorage("HideBottomTabLabelsEnabled") var isHiddenBottomTabLabels: Bool = false
    @State var alertItem: AlertItem?
    var body: some View {
        Form {
            Section(header: Text("File lists")) {
                Toggle(isOn: self.$isNSFWEnabled) {
                    Text("Show NSFW files")
                }
                Toggle(isOn: self.$isNSFWBlurred) {
                    Text("Blur NSFW files")
                }.disabled(!self.isNSFWEnabled)
            }

            Section(header: Text("Preferred upload format"), footer: Text("PNG has higher quality at the expense of time. JPEG produces acceptable quality with faster speeds.")) {
                Picker("Preferred upload format", selection: self.$preferredUploadFormat) {
                    Text("PNG").tag("png")
                    Text("JPEG").tag("jpeg")
                }
            }
            
            Section(header: Text("App appearance")) {
                Toggle(isOn: self.$isHiddenBottomTabLabels) {
                    Text("Hide bottom tab labels")
                }
            }

            Section(header: Text("Maintainance")) {
                Button(action: {
                    self.clearCache()
                }) {
                    HStack {
                        Text("Clear cache")
                        Spacer()
                        Image(systemName: "trash")
                    }
                }.foregroundColor(.red)
            }
        }.navigationBarTitle("App settings")
        .alert(item: self.$alertItem) { item in
            Alert(title: item.title, message: item.message, dismissButton: item.dismissButton)
        }
    }
    
    func clearCache() {
        let cache = ImageCache.default
        cache.clearMemoryCache()
        cache.clearDiskCache()
        self.alertItem = AlertItem(title: Text("Image cache cleared"), message: nil, dismissButton: .default(Text("Okay")))
    }
}

struct AppSettingsScreen_Previews: PreviewProvider {
    static var previews: some View {
        AppSettingsScreen()
    }
}
