import SwiftUI

struct RootNavigationView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    @Environment(\.openWindow) private var openWindow

    @State private var isWelcomeSheetPresented: Bool = false
    
    @StateObject private var splitViewModel: SplitViewModel = SplitViewModel()
    @State private var selectedView: AppUserViews = .images
    
    var body: some View {
        NavigationSplitView {
            NavigationStack {
                Group {
                    switch self.selectedView {
                    case .images:
                        ImagesListView(splitViewModel: self.splitViewModel)
                    case .collections:
                        IconAndInformationView(
                            icon: "shippingbox",
                            heading: "Coming soon!",
                            subheading: "We're working hard to bring this into fruition.\nCheck back in a future update."
                        )
                        .navigationTitle("Collections")
                    }
                }
                .toolbar {
                    #if !targetEnvironment(macCatalyst)
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            self.globalViewModel.isSettingsPresented = true
                        }) {
                            Label("Settings", systemImage: "gear")
                        }
                    }
                    #endif
                    ToolbarItem {
                        Picker("View", selection: self.$selectedView) {
                            ForEach(AppUserViews.allCases) { view in
                                Label(view.localizedName, systemImage: view.icon)
                            }
                        }
                    }
                    #if !targetEnvironment(macCatalyst)
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: {
                            self.globalViewModel.isUploadsPresented = true
                        }) {
                            Label("Upload", systemImage: "plus")
                        }
                        .keyboardShortcut("n")
                    }
                    #endif
                }
            }
            .navigationDestination(for: IamagesCollection.self) { collection in

            }
        } detail: {
            ImageDetailView(splitViewModel: self.splitViewModel)
        }
        .onChange(of: self.globalViewModel.isLoggedIn) { isLoggedIn in
            if !isLoggedIn {
                self.splitViewModel.selectedImage = nil
                self.splitViewModel.selectedCollection = nil
            }
        }
        .onChange(of: self.selectedView) { _ in
            self.splitViewModel.selectedImage = nil
            self.splitViewModel.selectedCollection = nil
        }
        // Welcome sheet
        .modifier(AppWelcomeSheetModifier(isPresented: self.$isWelcomeSheetPresented))
        #if targetEnvironment(macCatalyst)
        .hideMacTitlebar()
        #else
        .fullScreenCover(isPresented: self.$globalViewModel.isSettingsPresented) {
            SettingsView(isPresented: self.$globalViewModel.isSettingsPresented)
        }
        .fullScreenCover(isPresented: self.$globalViewModel.isUploadsPresented) {
            UploadView(isPresented: self.$globalViewModel.isUploadsPresented)
        }
        #endif
        
    }
}

#if DEBUG
struct RootNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        RootNavigationView()
            .environmentObject(GlobalViewModel())
    }
}
#endif
