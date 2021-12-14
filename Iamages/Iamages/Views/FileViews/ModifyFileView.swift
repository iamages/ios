import SwiftUI

struct ModifyFileView: View {
    @EnvironmentObject var dataObservable: APIDataObservable
    
    @Binding var file: IamagesFile
    @Binding var feed: [IamagesFile]
    let type: FeedType
    
    @State var newDescription: String = ""
    @State var newNSFW: Bool = false
    @State var newPrivate: Bool = false
    @State var newHidden: Bool = false

    @Binding var isModifyFileSheetPresented: Bool
    @State var isBusy: Bool = false
    
    @State var modifyErrorText: String?
    @State var isModifyErrorAlertPresented: Bool = false
    
    func removeFromFeed () {
        if let fileIndex = self.feed.firstIndex(of: self.file) {
            self.feed.remove(at: fileIndex)
        }
    }
    
    func modify () async {
        self.isBusy = true
        var fileModifications: [FileModifiable] = []
        if self.newDescription != self.file.description {
            fileModifications.append(.description(self.newDescription))
        }
        if self.newNSFW != self.file.isNSFW {
            fileModifications.append(.isNSFW(self.newNSFW))
        }
        if self.newPrivate != self.file.isPrivate {
            fileModifications.append(.isPrivate(self.newPrivate))
        }
        if self.newHidden != self.file.isHidden {
            fileModifications.append(.isHidden(self.newHidden))
        }
        do {
            for fileModification in fileModifications {
                try await self.dataObservable.modifyFile(id: self.file.id, modify: fileModification)
                switch fileModification {
                case .description(let description):
                    self.file.description = description
                case .isNSFW(let isNSFW):
                    self.file.isNSFW = isNSFW
                case .isPrivate(let isPrivate):
                    self.file.isPrivate = isPrivate
                    if self.type == .publicFeed {
                        self.removeFromFeed()
                    }
                case .isHidden(let isHidden):
                    self.file.isHidden = isHidden
                    if self.type == .publicFeed {
                        self.removeFromFeed()
                    }
                }
            }
            self.isModifyFileSheetPresented = false
        } catch {
            self.isBusy = false
            self.modifyErrorText = error.localizedDescription
            self.isModifyErrorAlertPresented = true
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Description") {
                    TextField(self.file.description, text: self.$newDescription)
                        .disabled(self.isBusy)
                        .onAppear {
                            self.newDescription = self.file.description
                        }
                }
                Section(content: {
                    Group {
                        Toggle(isOn: self.$newNSFW) {
                            Text("NSFW")
                        }
                        .onAppear {
                            self.newNSFW = self.file.isNSFW
                        }
                        Toggle(isOn: self.$newPrivate) {
                            Text("Private")
                        }
                        .onAppear {
                            self.newPrivate = self.file.isPrivate
                        }
                        Toggle(isOn: self.$newHidden) {
                            Text("Hidden")
                        }
                        .onAppear {
                            self.newHidden = self.file.isHidden
                        }
                    }
                    .disabled(self.isBusy)
                }, header: {
                    Text("Options")
                }, footer: {
                    Text("Some changes may require feed refreshes to be reflected.")
                })
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !self.isBusy {
                        Button(action: {
                            self.isModifyFileSheetPresented = false
                        }) {
                            Label("Close", systemImage: "xmark")
                        }
                    }
                }
                ToolbarItem {
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
                        .keyboardShortcut(.escape)
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
        .interactiveDismissDisabled(self.isBusy)
    }
}

struct ModifyFileView_Previews: PreviewProvider {
    static var previews: some View {
        ModifyFileView(file: .constant(IamagesFile(id: "", description: "", isNSFW: false, isPrivate: false, isHidden: false, created: Date(), mime: "", width: 0, height: 0)), feed: .constant([]), type: .publicFeed, isModifyFileSheetPresented: .constant(false))
    }
}
