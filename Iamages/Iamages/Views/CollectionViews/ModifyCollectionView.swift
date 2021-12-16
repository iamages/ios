import SwiftUI

struct ModifyCollectionView: View {
    @EnvironmentObject var dataObservable: APIDataObservable
    
    @Binding var collection: IamagesCollection
    @Binding var feedCollections: [IamagesCollection]
    let type: FeedType
    @Binding var isModifyCollectionSheetPresented: Bool
    
    @State var newDescription: String = ""
    @State var newPrivate: Bool = false
    @State var newHidden: Bool = false
    
    @State var isBusy: Bool = false
    
    func modify () async {
        self.isBusy = true
        do {
            
            self.isModifyCollectionSheetPresented = false
        } catch {
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
                            self.isModifyCollectionSheetPresented = false
                        }) {
                            Label("Close", systemImage: "xmark")
                        }
                        .disabled(self.isBusy)
                    }
                }
                ToolbarItem {
                    if self.isBusy {
                        ProgressView()
                    } else {
                        Button(action: {
                            Task {
                                
                            }
                        }) {
                            Label("Apply", systemImage: "checkmark")
                        }
                    }
                }
            }
            .navigationTitle("Modify")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ModifyCollectionView_Previews: PreviewProvider {
    static var previews: some View {
        ModifyCollectionView(collection: .constant(IamagesCollection(id: "", description: "", isPrivate: false, isHidden: false, created: Date(), owner: nil)), feedCollections: .constant([]), type: .publicFeed, isModifyCollectionSheetPresented: .constant(false))
    }
}
