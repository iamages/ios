import SwiftUI

@main
struct IamagesApp: App {
    @StateObject var dataCentralObservable = IamagesDataCentral()
    var body: some Scene {
        WindowGroup {
            AppScreen().environmentObject(dataCentralObservable)
        }
    }
}
