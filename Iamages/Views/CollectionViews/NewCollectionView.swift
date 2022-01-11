import SwiftUI

struct NewCollectionView: View {
    @EnvironmentObject var dataObservable: APIDataObservable
    @Environment(\.presentationMode) var presentationMode
    
    @Binding var feedCollections: [IamagesCollection]
    
    @State var isBusy: Bool = false
    @State var collection: NewCollectionRequest = NewCollectionRequest(description: "No description yet.", isPrivate: false, isHidden: false)
    
    @State var errorAlertText: String?
    @State var isErrorAlertPresented: Bool = false
    
    func newCollection () async {
        self.isBusy = true
        do {
            self.feedCollections.insert(try await self.dataObservable.newCollection(request: self.collection), at: 0)
            self.presentationMode.wrappedValue.dismiss()
        } catch {
            self.errorAlertText = error.localizedDescription
            self.isErrorAlertPresented = true
            self.isBusy = false
        }
    }
    
    var body: some View {
        Form {
            Section("Description") {
                TextField("", text: self.$collection.description)
                    .disabled(self.isBusy)
            }
            Section("Options") {
                Group {
                    Toggle("Private", isOn: self.$collection.isPrivate)
                        .disabled(!self.dataObservable.isLoggedIn)
                    Toggle("Hidden", isOn: self.$collection.isHidden)
                }
                .disabled(self.isBusy)
            }
        }
        .toolbar {
            ToolbarItem {
                if self.isBusy {
                    ProgressView()
                } else {
                    Button(action: {
                        Task {
                            await self.newCollection()
                        }
                    }) {
                        Label("Create", systemImage: "plus")
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
        .customBindingAlert(title: "Create new collection failed", message: self.$errorAlertText, isPresented: self.$isErrorAlertPresented)
        .navigationTitle("New collection")
        .navigationBarBackButtonHidden(self.isBusy)
    }
}
