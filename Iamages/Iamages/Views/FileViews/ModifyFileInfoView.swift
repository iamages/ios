import SwiftUI

struct ModifyFileInfoView: View {
    @EnvironmentObject var dataObservable: APIDataObservable
    
    @Binding var file: IamagesFile
    @Binding var feed: [IamagesFile]
    let type: FeedType
    @Binding var isDeleted: Bool
    @Binding var isPresented: Bool
    
    @State var isBusy: Bool = false
    
    @State var newDescription: String = ""
    @State var newNSFW: Bool = false
    @State var newPrivate: Bool = false
    @State var newHidden: Bool = false
    
    @State var isToggleHelpPopoverPresented: Bool = false
    
    @State var modifyErrorText: String?
    @State var isModifyErrorAlertPresented: Bool = false
    
    func removeFromFeed () {
        if let fileIndex = self.feed.firstIndex(of: self.file) {
            self.feed.remove(at: fileIndex)
        }
    }
    
    func modify () async {
        self.isBusy = true
        var modifications: [FileModifiable] = []
        if self.newDescription != self.file.description {
            modifications.append(.description(self.newDescription))
        }
        if self.newNSFW != self.file.isNSFW {
            modifications.append(.isNSFW(self.newNSFW))
        }
        if self.newPrivate != self.file.isPrivate {
            modifications.append(.isPrivate(self.newPrivate))
        }
        if self.newHidden != self.file.isHidden {
            modifications.append(.isHidden(self.newHidden))
        }
        var isDeletionNeeded: Bool = false
        do {
            for modification in modifications {
                try await self.dataObservable.modifyFile(id: self.file.id, modify: modification)
                switch modification {
                case .description(let description):
                    self.file.description = description
                case .isNSFW(let isNSFW):
                    self.file.isNSFW = isNSFW
                case .isPrivate(let isPrivate):
                    self.file.isPrivate = isPrivate
                    if self.type == .publicFeed && isPrivate {
                        isDeletionNeeded = true
                    }
                case .isHidden(let isHidden):
                    self.file.isHidden = isHidden
                    if self.type == .publicFeed && isHidden {
                        isDeletionNeeded = true
                    }
                }
            }
            if isDeletionNeeded {
                self.removeFromFeed()
                self.isDeleted = true
            }
            self.isPresented = false
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
                        .disabled(self.dataObservable.currentAppUserInformation?.pfp == self.file.id)
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
                ToolbarItem(placement: .navigationBarLeading) {
                    if !self.isBusy {
                        Button(action: {
                            self.isPresented = false
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
        .interactiveDismissDisabled(self.isBusy)
    }
}
