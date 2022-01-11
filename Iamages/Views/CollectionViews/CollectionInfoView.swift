import SwiftUI

struct CollectionInfoView: View {
    @Binding var collection: IamagesCollection
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            List {
                Section("Description") {
                    Text(verbatim: self.collection.description)
                }
                Section("Options") {
                    Group {
                        Toggle("Private", isOn: self.$collection.isPrivate)
                        Toggle("Hidden", isOn: self.$collection.isHidden)
                    }
                    .disabled(true)
                }
                if let relativeTimeString = Formatter.localRelativeTime.string(for: self.collection.created) {
                    Section("Created") {
                        Text(relativeTimeString.capitalized)
                    }
                }
                if let owner = self.collection.owner {
                    Section("Owner") {
                        HStack {
                            ProfileImageView(username: owner)
                            Text(verbatim: owner)
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        self.isPresented = false
                    }) {
                       Label("Close", systemImage: "xmark")
                    }
                    .keyboardShortcut(.cancelAction)
                }
            }
            .navigationTitle("Info")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
    }
}
