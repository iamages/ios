import SwiftUI

struct UploadEditorView: View {
    enum Field {
        case description
        case lockKey
    }
    
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    @EnvironmentObject private var uploadsViewModel: UploadsViewModel

    @Binding var uploadContainer: IamagesUploadContainer

    @FocusState private var focusedField: Field?
    @State private var isLockWarningAlertPresented: Bool = false

    var body: some View {
        Form {
            Section("Description") {
                TextField("1-255 characters", text: self.$uploadContainer.information.description)
                    .focused(self.$focusedField, equals: .description)
            }
//            
            Section {
                Toggle("Private", isOn: self.$uploadContainer.information.isPrivate)
                    .disabled(!self.globalViewModel.isLoggedIn)
                Toggle("Lock", isOn: self.$uploadContainer.information.isLocked)
                if self.uploadContainer.information.isLocked {
                    SecureField("Password", text: self.$uploadContainer.information.lockKey)
                        .focused(self.$focusedField, equals: .lockKey)
                }
            } header: {
                Text("Ownership")
            } footer: {
                UploadOwnershipFooter(
                    isLoggedIn: self.globalViewModel.isLoggedIn,
                    isLocked: self.uploadContainer.information.isLocked
                )
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Editor")
        .navigationBarTitleDisplayMode(.inline)
        .lockBetaWarningAlert(
            isLocked: self.$uploadContainer.information.isLocked,
            currentIsLocked: false
        )
        .onAppear {
            self.focusedField = .description
        }
        .onChange(of: self.uploadContainer.information.isLocked) { isLocked in
            if isLocked {
                self.focusedField = .lockKey
            } else {
                self.focusedField = .description
            }
            self.uploadContainer.information.lockKey = ""
        }
        .toolbar {
            ToolbarItem {
                Button {
                    // Remove the field focus here.
                    // Apparently, if the field is still focused, index out of range
                    // will happen. Honestly don't know why this is the case.
                    self.focusedField = nil
                    self.uploadsViewModel.deleteUpload(id: self.uploadContainer.id)
                } label: {
                    Label("Delete upload", systemImage: "trash")
                }
            }
        }
    }
}

#if DEBUG
struct UploadEditorView_Previews: PreviewProvider {
    static var previews: some View {
        UploadEditorView(
            uploadContainer: .constant(previewUploadContainer)
        )
        .environmentObject(GlobalViewModel())
    }
}
#endif
