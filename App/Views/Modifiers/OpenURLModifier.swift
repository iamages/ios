import SwiftUI
import AlertToast

struct OpenURLModifier: ViewModifier {
    struct NoBindingView: View {
        @Binding var isPresented: Bool
        
        var body: some View {
            Text("The requested resource is not available")
                .navigationTitle("Open URL")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem {
                        Button(action: {
                            self.isPresented = false
                        }) {
                            Label("Close", systemImage: "xmark")
                        }
                    }
                }
        }
    }
    
    struct ImageViewerView: View {
        @EnvironmentObject private var globalViewModel: GlobalViewModel
        @EnvironmentObject private var splitViewModel: SplitViewModel
        
        @Binding var isPresented: Bool
        
        var body: some View {
            NavigationStack {
                if let id = self.splitViewModel.selectedImage,
                   let i = self.splitViewModel.images.firstIndex(where: { $0.id == id }),
                   let imageAndMetadata = self.$splitViewModel.images[safe: i]
                {
                    ImageDetailView(imageAndMetadata: imageAndMetadata)
                        .environmentObject(self.globalViewModel)
                        .environmentObject(self.splitViewModel)
                } else {
                    NoBindingView(isPresented: self.$isPresented)
                }
            }
            .onDisappear {
                self.splitViewModel.selectedImage = nil
                self.splitViewModel.images = []
            }
        }
    }
    
    struct CollectionViewerView: View {
        @EnvironmentObject private var globalViewModel: GlobalViewModel
        @EnvironmentObject private var splitViewModel: SplitViewModel
        
        @Binding var isPresented: Bool
        @Binding var selectedCollection: String?
        @Binding var collections: [IamagesCollection]
        
        var body: some View {
            NavigationSplitView {
                if let id = self.selectedCollection,
                   let i = self.collections.firstIndex(where: { $0.id == id }),
                   let collection = self.$collections[safe: i]
                {
                    CollectionImagesListView(collection: collection)
                        .environmentObject(self.globalViewModel)
                        .environmentObject(self.splitViewModel)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button {
                                    self.isPresented = false
                                } label: {
                                    Label("Close", systemImage: "xmark")
                                }
                            }
                        }
                } else {
                    NoBindingView(isPresented: self.$isPresented)
                }
            } detail: {
                if let id = self.splitViewModel.selectedImage,
                   let i = self.splitViewModel.images.firstIndex(where: { $0.id == id }),
                   let imageAndMetadata = self.$splitViewModel.images[i]
                {
                    ImageDetailView(imageAndMetadata: imageAndMetadata)
                        .environmentObject(self.globalViewModel)
                        .environmentObject(self.splitViewModel)
                } else {
                    Text("Select an image")
                }
            }
            .onDisappear {
                self.selectedCollection = nil
                self.collections = []
                self.splitViewModel.selectedImage = nil
                self.splitViewModel.images = []
            }
        }
    }
    
    @ObservedObject var globalViewModel: GlobalViewModel

    @StateObject private var splitViewModel = SplitViewModel()

    @State private var collections: [IamagesCollection] = []
    @State private var selectedCollection: String?

    @State private var isLoadingToastPresented = false
    @State private var isImageSheetPresented = false
    @State private var isCollectionSheetPresented = false
    @State private var error: LocalizedAlertError?
    
    private func validateURL(url: URL) -> Bool {
        if (url.host() == "iamages.jkelol111.me" || url.scheme == "iamages") &&
           (url.pathComponents[safe: 1] == "api" && url.pathComponents.last == "embed")
        {
            return true
        }
        return false
    }
    
    func body(content: Content) -> some View {
        content
            .errorAlert(error: self.$error)
            .toast(isPresenting: self.$isLoadingToastPresented) {
                AlertToast(displayMode: .alert, type: .loading)
            }
            .sheet(isPresented: self.$isImageSheetPresented) {
                ImageViewerView(isPresented: self.$isImageSheetPresented)
                    .environmentObject(self.globalViewModel)
                    .environmentObject(self.splitViewModel)
            }
            .sheet(isPresented: self.$isCollectionSheetPresented) {
                CollectionViewerView(
                    isPresented: self.$isCollectionSheetPresented,
                    selectedCollection: self.$selectedCollection,
                    collections: self.$collections
                )
                .environmentObject(self.globalViewModel)
                .environmentObject(self.splitViewModel)
            }
            .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                guard let url = activity.webpageURL else {
                    return
                }
                if !self.validateURL(url: url) { return }
                UIApplication.shared.open(url, options: [.universalLinksOnly: true])
            }
            .onOpenURL { url in
                if !self.validateURL(url: url) { return }
                self.isCollectionSheetPresented = false
                self.isImageSheetPresented = false
                self.isLoadingToastPresented = true
                
                switch url.pathComponents[safe: 2] {
                case "images":
                    if let id = url.pathComponents[safe: 3] {
                        print(id)
                        Task {
                            do {
                                let image = try await self.globalViewModel.getImagePublicMetadata(id: id)
                                var imageAndMetadata = IamagesImageAndMetadataContainer(
                                    id: id,
                                    image: image
                                )
                                if !image.lock.isLocked {
                                    imageAndMetadata.metadataContainer = try await self.globalViewModel.getImagePrivateMetadata(for: image)
                                }
                                self.splitViewModel.images.append(imageAndMetadata)
                                self.splitViewModel.selectedImage = image.id
                                self.isImageSheetPresented = true
                            } catch {
                                self.error = LocalizedAlertError(error: error)
                            }
                            self.isLoadingToastPresented = false
                        }
                    }
                case "collections":
                    if let id = url.pathComponents[safe: 3] {
                        Task {
                            do {
                                let collection = try self.globalViewModel.jsond.decode(
                                    IamagesCollection.self,
                                    from: try await self.globalViewModel.fetchData(
                                        "/collections/\(id)",
                                        method: .get,
                                        authStrategy: .whenPossible
                                    ).0
                                )
                                self.collections.append(collection)
                                self.selectedCollection = collection.id
                                self.isCollectionSheetPresented = true
                            } catch {
                                self.error = LocalizedAlertError(error: error)
                            }
                            self.isLoadingToastPresented = false
                        }
                    }
                default:
                    self.isLoadingToastPresented = false
                }
            }
    }
}
