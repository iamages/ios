import SwiftUI
import class Kingfisher.ImageCache

struct AppSettingsScreen: View {
    @AppStorage("NSFWEnabled") var isNSFWEnabled: Bool = false
    @AppStorage("PreferredUploadFormat") var preferredUploadFormat: String = "png"
    @State var alertItem: AlertItem?
    var body: some View {
        Form {
            Section(header: Text("File lists")) {
                Toggle(isOn: $isNSFWEnabled) {
                    Text("Show NSFW files")
                }
            }

            Section(header: Text("Preferred upload format"), footer: Text("PNG has higher quality at the expense of time. JPEG produces acceptable quality with faster speeds.")) {
                Picker("Preferred upload format", selection: self.$preferredUploadFormat) {
                    Text("PNG").tag("png")
                    Text("JPEG").tag("jpeg")
                }.pickerStyle(SegmentedPickerStyle())
            }

            Section(header: Text("Maintainance"), footer: Text("These options are for ADVANCED users only. You're on your own using these!")) {
                Button(action: {
                    clearCache()
                }) {
                    HStack {
                        Text("Clear cache")
                        Spacer()
                        Image(systemName: "trash.slash")
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
