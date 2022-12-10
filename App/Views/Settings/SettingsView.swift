import SwiftUI
import Nuke
import StoreKit
import SPConfetti
import WidgetKit

struct SettingsView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    
    #if !targetEnvironment(macCatalyst)
    @Binding var isPresented: Bool
    #endif
    
    @State private var isBusy: Bool = false
    
    #if !targetEnvironment(macCatalyst)
    @ViewBuilder
    private var closeButton: some View {
        Button(action: {
            self.isPresented = false
        }) {
            Label("Close", systemImage: "xmark")
        }
        .disabled(self.isBusy)
    }
    #endif
    
    var body: some View {
        NavigationSplitView {
            List(
                AppSettingsViews.allCases,
                selection: self.$globalViewModel.selectedSettingsView
            ) { settingsView in
                NavigationLink(value: settingsView) {
                    Label(settingsView.localizedName, systemImage: settingsView.icon)
                }
                .disabled(self.isBusy)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            #if !targetEnvironment(macCatalyst)
            .toolbar {
                if self.horizontalSizeClass == .compact {
                    ToolbarItem {
                        self.closeButton
                    }
                }
            }
            #endif
        } detail: {
            NavigationStack {
                if let selectedSettingsView = self.globalViewModel.selectedSettingsView {
                    Form {
                        switch selectedSettingsView {
                        case .account:
                            AccountSettingsView()
                        case .uploads:
                            UploadDefaultsSettingsView()
                        case .tips:
                            TipJarSettingsView(isBusy: self.$isBusy)
                        case .maintainance:
                            MaintainanceSettingsView()
                        case .about:
                            AboutSettingsView(isBusy: self.$isBusy)
                        }
                    }
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationTitle(selectedSettingsView.localizedName)
                    #if !targetEnvironment(macCatalyst)
                    .toolbar {
                        if self.horizontalSizeClass == .regular {
                            ToolbarItem {
                                self.closeButton
                            }
                        }
                    }
                    #endif
                } else {
                    Text("Select a settings category on the sidebar")
                }
            }
            
        }
        // Set window title for Mac Catalyst.
        .navigationTitle("Settings")
        .onAppear {
            if self.globalViewModel.selectedSettingsView == nil && self.horizontalSizeClass != .compact {
                self.globalViewModel.selectedSettingsView = .account
            }
        }
        .onDisappear {
            self.globalViewModel.selectedSettingsView = nil
        }
    }
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        #if targetEnvironment(macCatalyst)
        SettingsView()
            .environmentObject(GlobalViewModel())
        #else
        SettingsView(isPresented: .constant(true))
            .environmentObject(GlobalViewModel())
        #endif
    }
}
#endif
