import SwiftUI

struct UploadingNewCollectionView: View {
    @EnvironmentObject var dataObservable: APIDataObservable

    @Binding var newCollection: NewCollectionRequest
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            Form {
                Section("Description") {
                    TextField("", text: self.$newCollection.description)
                }
                Section("Options") {
                    Toggle("Private", isOn: self.$newCollection.isPrivate)
                        .disabled(!self.dataObservable.isLoggedIn)
                    Toggle("Hidden", isOn: self.$newCollection.isHidden)
                }
            }
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        self.isPresented = false
                    }) {
                        Label("Confirm", systemImage: "checkmark")
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
            .navigationTitle("New collection")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
