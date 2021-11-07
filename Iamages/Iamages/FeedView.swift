import SwiftUI

enum Feeds {
    case latest
    case popular
    case random
}

struct FeedView: View {
    @State var selectedFeed: Feeds = .latest
    
    var main: some View {
        List {
            
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Picker("Feed", selection: self.$selectedFeed) {
                    Text("Latest").tag(Feeds.latest)
                    Text("Popular").tag(Feeds.popular)
                    Text("Random").tag(Feeds.random)
                }.labelsHidden()
            }
            #if targetEnvironment(macCatalyst)
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    
                }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }.keyboardShortcut("r")
            }
            #endif
        }
        .navigationTitle("Feed")
    }

    var body: some View {
        #if targetEnvironment(macCatalyst)
        main
        #else
        NavigationView {
            main
        }
        #endif
    }
}

struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView()
    }
}
