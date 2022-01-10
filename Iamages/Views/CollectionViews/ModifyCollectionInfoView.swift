import SwiftUI

struct ModifyCollectionInfoView: View {
    @EnvironmentObject var dataObservable: APIDataObservable
    
    @Binding var collection: IamagesCollection
    @Binding var feed: [IamagesCollection]
    let type: FeedType
    @Binding var isDeleted: Bool
    @Binding var isPresented: Bool
    
    @State var newDescription: String = ""
    @State var newPrivate: Bool = false
    @State var newHidden: Bool = false
    
    @State var isToggleHelpPopoverPresented: Bool = false
    
    @State var isBusy: Bool = false
    @State var isModifyErrorAlertPresented: Bool = false
    @State var modifyErrorText: String?
    
    func removeFromFeed () {
        if let fileIndex = self.feed.firstIndex(of: self.collection) {
            self.feed.remove(at: fileIndex)
        }
    }
    
    func modify () async {
        self.isBusy = true
        var modifications: [CollectionModifiable] = []
        if self.newDescription != self.collection.description {
            modifications.append(.description(self.newDescription))
        }
        if self.newPrivate != self.collection.isPrivate {
            modifications.append(.isPrivate(self.newPrivate))
        }
        if self.newHidden != self.collection.isHidden {
            modifications.append(.isHidden(self.newHidden))
        }
        var isDeletionNeeded: Bool = false
        do {
            for modification in modifications {
                try await self.dataObservable.modifyCollection(id: self.collection.id, modify: modification)
                switch modification {
                case .description(let description):
                    self.collection.description = description
                case .isHidden(let isHidden):
                    self.collection.isHidden = isHidden
                    if self.type == .publicFeed && isHidden {
                        isDeletionNeeded = true
                    }
                case .isPrivate(let isPrivate):
                    self.collection.isPrivate = isPrivate
                    if self.type == .publicFeed && isPrivate {
                        isDeletionNeeded = true
                    }
                default:
                    break
                }
            }
            if isDeletionNeeded {
                self.removeFromFeed()
                self.isDeleted = true
            }
            self.isPresented = false
        } catch {
            self.modifyErrorText = error.localizedDescription
            self.isModifyErrorAlertPresented = true
            self.isBusy = false
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Description") {
                    TextField(self.collection.description, text: self.$newDescription)
                        .disabled(self.isBusy)
                        .onAppear {
                            self.newDescription = self.collection.description
                        }
                }
                Section(content: {
                    Group {
                        Toggle("Private", isOn: self.$newPrivate)
                            .onAppear {
                                self.newPrivate = self.collection.isPrivate
                            }
                        Toggle("Hidden", isOn: self.$newHidden)
                            .onAppear {
                                self.newHidden = self.collection.isHidden
                            }
                    }
                    .disabled(self.isBusy)
                    Button("Help") {
                        self.isToggleHelpPopoverPresented = true
                    }
                    .popover(isPresented: self.$isToggleHelpPopoverPresented) {
                        TogglesHelpView()
                    }
                }, header: {
                    Text("Options")
                }, footer: {
                    Text("Some changes may require feed refreshes to be reflected.")
                })
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if !self.isBusy {
                        Button(action: {
                            self.isPresented = false
                        }) {
                            Label("Close", systemImage: "xmark")
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if self.isBusy {
                        ProgressView()
                    } else {
                        Button(action: {
                            Task {
                                await self.modify()
                            }
                        }) {
                            Label("Apply", systemImage: "checkmark")
                        }
                        .keyboardShortcut(.defaultAction)
                    }
                }
            }
            .alert("Modification failed", isPresented: self.$isModifyErrorAlertPresented) {
                Button("Retry") {
                    Task {
                        await self.modify()
                    }
                }
                Button("Stop", role: .cancel) {}
            } message: {
                Text(self.modifyErrorText ?? "Unknown error")
            }
            .navigationTitle("Modify")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
