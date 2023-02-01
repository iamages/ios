import SwiftUI
import AlertToast

struct OpenURLModifier: ViewModifier {
    @ObservedObject var globalViewModel: GlobalViewModel
    
    
    @StateObject private var splitViewModel = SplitViewModel()
    
    @State private var imageAndMetadata: IamagesImageAndMetadataContainer?
    @State private var collection: IamagesCollection?
    @State private var isLoadingToastPresented = false
    @State private var isImageSheetPresented = false
    @State private var isCollectionSheetPresented = false
    @State private var error: LocalizedAlertError?
    
    @ViewBuilder
    private var noBinding: some View {
        Text("The requested resource is not available")
            .navigationTitle("Open URL")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        self.isImageSheetPresented = false
                        self.isCollectionSheetPresented = false
                    }) {
                        Label("Close", systemImage: "xmark")
                    }
                }
            }
    }
    
    func body(content: Content) -> some View {
        content
            .errorAlert(error: self.$error)
            .toast(isPresenting: self.$isLoadingToastPresented) {
                AlertToast(displayMode: .alert, type: .loading)
            }
            .sheet(isPresented: self.$isImageSheetPresented, onDismiss: {
                self.imageAndMetadata = nil
            }) {
                NavigationStack {
                    if let imageAndMetadata = Binding<IamagesImageAndMetadataContainer>(self.$imageAndMetadata) {
                        ImageDetailView(imageAndMetadata: imageAndMetadata)
                            .environmentObject(self.globalViewModel)
                            .environmentObject(self.splitViewModel)
                    } else {
                        self.noBinding
                    }
                }
            }
            .sheet(isPresented: self.$isCollectionSheetPresented, onDismiss: {
                self.collection = nil
            }) {
                NavigationSplitView {
                    if let collection = Binding<IamagesCollection>(self.$collection) {
                        CollectionImagesListView(collection: collection)
                            .environmentObject(self.globalViewModel)
                            .environmentObject(self.splitViewModel)
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarLeading) {
                                    Button {
                                        self.isCollectionSheetPresented = false
                                    } label: {
                                        Label("Close", systemImage: "xmark")
                                    }
                                }
                            }
                    } else {
                        self.noBinding
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
            }
            .onOpenURL { url in
                print(url)
                if url.host() != "iamages.jkelol111.me" ||
                   url.scheme != "iamages" ||
                   url.pathComponents.first != "api",
                   url.pathComponents.last != "embed"
                {
                    return
                }
                self.isLoadingToastPresented = true
                
                switch url.pathComponents[safe: 1] {
                case "images":
                    if let id = url.pathComponents[safe: 2] {
                        Task {
                            do {
                                let image = try await self.globalViewModel.getImagePublicMetadata(id: id)
                                self.imageAndMetadata = IamagesImageAndMetadataContainer(
                                    id: id,
                                    image: image
                                )
                                if !image.lock.isLocked {
                                    self.imageAndMetadata?.metadataContainer = try await self.globalViewModel.getImagePrivateMetadata(for: image)
                                }
                                self.isImageSheetPresented = true
                            } catch {
                                self.error = LocalizedAlertError(error: error)
                            }
                            self.isLoadingToastPresented = false
                        }
                    }
                case "collections":
                    if let id = url.pathComponents[safe: 2] {
                        Task {
                            do {
                                self.collection = try self.globalViewModel.jsond.decode(
                                    IamagesCollection.self,
                                    from: try await self.globalViewModel.fetchData(
                                        "/collections/\(id)",
                                        method: .get,
                                        authStrategy: .whenPossible
                                    ).0
                                )
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
