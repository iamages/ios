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
    @AppStorage("HideBottomTabLabelsEnabled") var isHiddenBottomTabLabels: Bool = false
    var body: some View {
        TabView {
            LatestScreen().tabItem {
                Image(systemName: "clock")
                if !self.isHiddenBottomTabLabels {
                    Text("Latest")
                }
            }
            SearchScreen().tabItem {
                Image(systemName: "magnifyingglass")
                if !self.isHiddenBottomTabLabels {
                    Text("Search")
                }
            }
            UploadScreen().tabItem {
                Image(systemName: "square.and.arrow.up")
                if !self.isHiddenBottomTabLabels {
                    Text("Upload")
                }
            }
            UserScreen().tabItem {
                Image(systemName: "person.crop.circle")
                if !self.isHiddenBottomTabLabels {
                    Text("User")
                }
            }
            SettingsScreen().tabItem {
                Image(systemName: "gearshape")
                if !self.isHiddenBottomTabLabels {
                    Text("Settings")
                }
            }
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        AppScreen()
    }
}
