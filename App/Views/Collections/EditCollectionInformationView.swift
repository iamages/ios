import SwiftUI

struct EditCollectionInformationView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    @Environment(\.dismiss) private var dismiss
    
    @Binding var collection: IamagesCollection

    @State private var description: String = ""
    @State private var isPrivate: Bool = false
    
    @State private var isBusy: Bool = false
    @State private var error: LocalizedAlertError?
    @State private var isCancelAlertPresented: Bool = false
    @FocusState private var isDescriptionFieldFocused: Bool
    
    private func edit() async {
        self.isBusy = true
        self.isDescriptionFieldFocused = false
        var edits: [IamagesCollectionEdit] = []
        do {
            if self.description != self.collection.description {
                edits.append(.init(change: .description, to: .string(self.description)))
            }
            if self.isPrivate != self.collection.isPrivate {
                edits.append(.init(change: .isPrivate, to: .bool(self.isPrivate)))
            }
            for edit in edits {
                try await self.globalViewModel.fetchData(
                    "/collections/\(self.collection.id)",
                    method: .patch,
                    body: try self.globalViewModel.jsone.encode(edit),
                    contentType: .json,
                    authStrategy: .required
                )
                switch edit.change {
                case .description:
                    switch edit.to {
                    case .string(let description):
                        self.collection.description = description
                    default:
                        throw BoolOrStringError.wrongType("description", .string)
                    }
                case .isPrivate:
                    switch edit.to {
                    case .bool(let isPrivate):
                        self.collection.isPrivate = isPrivate
                    default:
                        throw BoolOrStringError.wrongType("isPrivate", .bool)
                    }
                default:
                    break
                }
            }
            self.dismiss()
        } catch {
            self.isBusy = false
            self.isDescriptionFieldFocused = true
            self.error = LocalizedAlertError(error: error)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Description") {
                    TextField("Description cannot be empty!", text: self.$description)
                        .focused(self.$isDescriptionFieldFocused)
                }
                Section("Ownership") {
                    Toggle("Private", isOn: self.$isPrivate)
                }
            }
            .navigationTitle("Edit collection")
            .navigationBarTitleDisplayMode(.inline)
            .errorAlert(error: self.$error)
            .onAppear {
                self.description = self.collection.description
                self.isPrivate = self.collection.isPrivate
                self.isDescriptionFieldFocused = true
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if self.description != self.collection.description ||
                           self.isPrivate != self.collection.isPrivate
                        {
                            self.isCancelAlertPresented = true
                        } else {
                            self.dismiss()
                        }
                    }
                    .disabled(self.isBusy)
                    .confirmCancelDialog(
                        isPresented: self.$isCancelAlertPresented
                    )
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        Task {
                            await self.edit()
                        }
                    }
                    .disabled(self.isBusy || self.description.isEmpty)
                }
            }
        }
    }
}

#if DEBUG
struct EditCollectionInformationView_Previews: PreviewProvider {
    static var previews: some View {
        EditCollectionInformationView(
            collection: .constant(previewCollection)
        )
        .environmentObject(GlobalViewModel())
    }
}
#endif
