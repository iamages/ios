import SwiftUI

struct AlertItem: Identifiable {
    var id = UUID()
    var title: Text
    var message: Text?
    var dismissButton: Alert.Button?
}

let api = IamagesAPI()
let auth = IamagesUserAuthHelpers()

struct AppScreen: View {
    var body: some View {
        TabView {
            LatestScreen().tabItem {
                Image(systemName: "clock.fill")
                Text("Latest")
            }
            RandomScreen().tabItem {
                Image(systemName: "photo.fill.on.rectangle.fill")
                Text("Random")
            }
            UploadScreen().tabItem {
                Image(systemName: "square.and.arrow.up.fill")
                Text("Upload")
            }
            UserScreen().tabItem {
                Image(systemName: "person.crop.circle.fill")
                Text("User")
            }
            SettingsScreen().tabItem {
                Image(systemName: "gearshape.fill")
                Text("Settings")
            }
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        AppScreen()
    }
}
