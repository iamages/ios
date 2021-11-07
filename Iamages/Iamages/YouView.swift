import SwiftUI

enum UserLists {
    case files
    case collections
}

struct YouView: View {
    @State var selectedList: UserLists = .files
    @State var isBusy: Bool = true
    
    var main: some View {
        List {
            
        }
        #if !targetEnvironment(macCatalyst)
        .refreshable {
            self.isBusy = true
            self.isBusy = false
        }
        #endif
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Picker("List", selection: self.$selectedList) {
                    Text("Files")
                        .tag(UserLists.files)
                    Text("Collections")
                        .tag(UserLists.collections)
                }
                .labelsHidden()
                .disabled(self.isBusy)
            }
            #if targetEnvironment(macCatalyst)
            ToolbarItem(placement: .navigationBarLeading) {
                if self.isBusy {
                    ProgressView()
                        .progressViewStyle(.circular)
                }
            }
            #endif
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    
                }) {
                    Label("User", systemImage: "person.circle")
                }
                .disabled(self.isBusy)
            }
            #if targetEnvironment(macCatalyst)
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    
                }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .keyboardShortcut("r")
                .disabled(self.isBusy)
            }
            #endif
        }
        .navigationTitle("You")
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

struct YouView_Previews: PreviewProvider {
    static var previews: some View {
        YouView()
    }
}
