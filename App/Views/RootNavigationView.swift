import SwiftUI

struct RootNavigationView: View {
    @EnvironmentObject private var appDelegate: AppDelegate
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    @Environment(\.scenePhase) private var scenePhase
    
    @StateObject private var splitViewModel: SplitViewModel = SplitViewModel()
    
    var body: some View {
        NavigationSplitView {
            Group {
                switch self.splitViewModel.selectedView {
                case .images:
                    ImagesListView()
                case .collections:
                    CollectionsListView(viewMode: .normal)
                case .sharedWithYou:
                    SharedWithYouListView()
                case .anonymousUploads:
                    AnonymousUploadsListView()
                }
            }
            .environmentObject(self.splitViewModel)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarTitleMenu {
                    Picker("View", selection: self.$splitViewModel.selectedView.animation()) {
                        ForEach(AppUserViews.allCases) { view in
                            Label(view.localizedName, systemImage: view.icon)
                                .tag(view)
                        }
                    }
                    .pickerStyle(.inline)
                }
                #if !targetEnvironment(macCatalyst)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        self.globalViewModel.isSettingsPresented = true
                    }) {
                        Label("Settings", systemImage: "gear")
                    }
                }
                #endif
            }
        } detail: {
            ZStack {
                if let id = self.splitViewModel.selectedImage,
                   let i = self.splitViewModel.images.firstIndex(where: { $0.id == id }),
                   let imageAndMetadata = self.$splitViewModel.images[i]
                {
                    ImageDetailView(
                        imageAndMetadata: imageAndMetadata
                    )
                    .environmentObject(self.splitViewModel)
                    // MARK: Inactive app locked image blur
                    if imageAndMetadata.wrappedValue.image.lock.isLocked == true &&
                       self.scenePhase == .inactive
                    {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.white)
                                    .font(.largeTitle)
                                    .shadow(radius: 0.6)
                                Spacer()
                            }
                            Spacer()
                        }
                        .background(.thickMaterial)
                    }
                } else {
                    Text("Select an image")
                        #if targetEnvironment(macCatalyst)
                        .navigationSubtitle("")
                        #endif
                }
            }
        }
        // For Mac Catalyst window title
        .navigationTitle(self.splitViewModel.selectedView.localizedName)
        // Handle quick actions
        .onChange(of: self.appDelegate.shortcutItem) { item in
            if let quickActionType = self.appDelegate.shortcutItem?.type,
               let appView = AppUserViews(rawValue: quickActionType)
            {
                AppDelegate.shortcutItem = nil
                withAnimation {
                    self.splitViewModel.selectedView = appView
                }
            }
        }
        .onChange(of: self.globalViewModel.isLoggedIn) { isLoggedIn in
            if !isLoggedIn {
                self.splitViewModel.selectedImage = nil
                self.splitViewModel.images = []
            }
        }
        .onChange(of: self.splitViewModel.selectedView) { _ in
            self.splitViewModel.selectedImage = nil
            self.splitViewModel.images = []
        }
        // Welcome sheet
        .modifier(AppWelcomeSheetModifier())
        // Delete image listener
        .deleteImageListener(splitViewModel: self.splitViewModel)
        #if targetEnvironment(macCatalyst)
        .hideMacTitlebar()
        #else
        .sheet(isPresented: self.$globalViewModel.isNewCollectionPresented) {
            NewCollectionView()
        }
        .fullScreenCover(isPresented: self.$globalViewModel.isUploadsPresented) {
            UploadsView()
        }
        .fullScreenCover(isPresented: self.$globalViewModel.isSettingsPresented) {
            SettingsView()
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
