import SwiftUI

struct RootNavigationView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    @Environment(\.openWindow) private var openWindow
    @Environment(\.scenePhase) private var scenePhase

    @State private var isWelcomeSheetPresented: Bool = false
    
    @StateObject private var splitViewModel: SplitViewModel = SplitViewModel()
    @State private var selectedView: AppUserViews = .images
    @State private var isNewCollectionSheetPresented: Bool = false
    
    var body: some View {
        NavigationSplitView {
            Group {
                switch self.selectedView {
                case .images:
                    ImagesListView(splitViewModel: self.splitViewModel)
                case .collections:
                    CollectionsListView(
                        splitViewModel: self.splitViewModel,
                        viewMode: .normal,
                        imageID: nil
                    )
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
                    Picker("View", selection: self.$selectedView.animation()) {
                        ForEach(AppUserViews.allCases) { view in
                            Label(view.localizedName, systemImage: view.icon)
                                .tag(view)
                        }
                    }
                }
                #if !targetEnvironment(macCatalyst)
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: {
                            self.globalViewModel.isUploadsPresented = true
                        }) {
                            Label("Uploads", systemImage: "square.and.arrow.up.on.square")
                        }
                        Button(action: {
                            self.globalViewModel.isNewCollectionPresented = true
                        }) {
                            Label("Collection", systemImage: "folder.badge.plus")
                        }
                    } label: {
                        Label("New", systemImage: "plus")
                    }
                }
                #endif
            }
        } detail: {
            ZStack {
                ImageDetailView(splitViewModel: self.splitViewModel)
                // MARK: Inactive app locked image blur
                if self.splitViewModel.selectedImage?.lock.isLocked == true &&
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
                    .background(.regularMaterial)
                }
            }
        }
        .navigationTitle(self.selectedView.localizedName)
        .onChange(of: self.globalViewModel.isLoggedIn) { isLoggedIn in
            if !isLoggedIn {
                withAnimation {
                    self.splitViewModel.selectedImage = nil
                }
            }
        }
        .onChange(of: self.selectedView) { _ in
            withAnimation {
                self.splitViewModel.selectedImage = nil
            }
        }
        // Welcome sheet
        .modifier(AppWelcomeSheetModifier())
        #if targetEnvironment(macCatalyst)
        .hideMacTitlebar()
        #else
        .fullScreenCover(isPresented: self.$globalViewModel.isSettingsPresented) {
            SettingsView()
        }
        .fullScreenCover(isPresented: self.$globalViewModel.isUploadsPresented) {
            UploadsView()
        }
        .sheet(isPresented: self.$globalViewModel.isNewCollectionPresented) {
            NewCollectionView()
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
