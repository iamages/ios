import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: ViewModel
    
    #if !os(macOS)
    @Binding var isPresented: Bool
    #endif

    @State private var isDeleteAccountAlertPresented: Bool = false
    @State private var isLoginSheetPresented: Bool = false
    
    @ViewBuilder
    private var account: some View {
        if let userInformation: IamagesUser = self.viewModel.userInformation {
            VStack(alignment: .leading) {
                Text(userInformation.username)
                    .font(.title2)
                    .bold()
                LabeledContent("Created on") {
                    Text(userInformation.createdOn, format: .dateTime)
                }
            }
            Button("Change password") {
                
            }
            Button("Delete account", role: .destructive) {
                self.isDeleteAccountAlertPresented = true
            }
        } else {
            Button("Login/signup") {
                self.isLoginSheetPresented = true
            }
        }
    }
    
    @ViewBuilder
    private var uploadDefaults: some View {
        Toggle("Private", isOn: .constant(false))
        Toggle("Locked", isOn: .constant(false))
    }
    
    @ViewBuilder
    private var tip: some View {
        HStack {
            Button(action: {
                
            }) {
                
            }
        }
    }
    
    var body: some View {
        #if os(macOS)
        TabView {
            Form {
                self.uploadDefaults
            }
            .tabItem {
                Label("Accounts", systemImage: "person.2")
            }
        }
        #else
        NavigationStack {
            Form {
                Section("Account") {
                    self.account
                }
                Section {
                    self.uploadDefaults
                } header: {
                    Text("Default for new uploads")
                } footer: {
                    Text("Private: shared links will not work.\nLocked: files will be encrypted with a password you set while uploading.")
                }
                Section {
                    HelpLinksView()
                } header: {
                    Text("About + info")
                } footer: {
                    Text("Iamages \(Bundle.main.version) (\(Bundle.main.build))\n\(Bundle.main.copyright)")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: self.$isLoginSheetPresented) {
                LoginSheetView(isPresented: self.$isLoginSheetPresented)
            }
            .toolbar {
                Button(action: {
                    self.isPresented = false
                }) {
                    Label("Close", systemImage: "xmark")
                }
            }
        }
        #endif
    }
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        #if os(macOS)
        SettingsView()
            .environmentObject(ViewModel())
        #else
        SettingsView(isPresented: .constant(true))
            .environmentObject(ViewModel())
        #endif
    }
}
#endif
