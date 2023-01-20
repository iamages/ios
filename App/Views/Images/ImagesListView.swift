import SwiftUI

struct ImagesListView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    @EnvironmentObject private var splitViewModel: SplitViewModel

    @State private var isBusy: Bool = false
    @State private var isFirstAppearance: Bool = true
    @State private var isEndOfFeed: Bool = false
    @State private var error: LocalizedAlertError?
    
    @State private var queryString: String = ""
    @State private var querySuggestions: [String] = []

    private func pageFeed() async {
        self.isBusy = true
        
        do {
            let newImages: [IamagesImage] = try self.globalViewModel.jsond.decode(
                [IamagesImage].self,
                from: await self.globalViewModel.fetchData(
                    "/users/images",
                    method: .post,
                    body: self.globalViewModel.jsone.encode(
                        Pagination(
                            query: self.queryString.isEmpty ? nil : self.queryString,
                            lastID: self.splitViewModel.images.last?.id
                        )
                    ),
                    contentType: .json,
                    authStrategy: .required
                ).0
            )
            if newImages.count < 6 {
                self.isEndOfFeed = true
            }
            withAnimation {
                self.splitViewModel.images.append(
                    contentsOf: newImages.map({ IamagesImageAndMetadataContainer(id: $0.id, image: $0) })
                )
            }
        } catch {
            self.error = LocalizedAlertError(error: error)
        }

        self.isBusy = false
    }
    
    private func startFeed() async {
        self.splitViewModel.selectedImage = nil
        self.splitViewModel.images = []
        self.isEndOfFeed = false
        await self.pageFeed()
    }
    
    private func loadSuggestions() async {
        if self.queryString.isEmpty {
            self.querySuggestions = []
            return
        }
        do {
            self.querySuggestions = try self.globalViewModel.jsond.decode(
                [String].self,
                from: await self.globalViewModel.fetchData(
                    "/users/images/suggestions",
                    method: .post,
                    body: self.queryString.data(using: .utf8),
                    contentType: .text,
                    authStrategy: .required
                ).0
            )
        } catch {
            self.querySuggestions = []
        }
    }
    
    @ViewBuilder
    private var list: some View {
        List(selection: self.$splitViewModel.selectedImage) {
            ForEach(self.$splitViewModel.images) { imageAndMetadata in
                NavigableImageView(imageAndMetadata: imageAndMetadata)
                    .task {
                        if !self.isEndOfFeed && self.splitViewModel.images.last?.id == imageAndMetadata.wrappedValue.id {
                            await pageFeed()
                        }
                    }
            }
            if self.isBusy {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            }
        }
        .errorToast(error: self.$error)
        .task {
            if self.isFirstAppearance {
                self.isFirstAppearance = false
                await self.startFeed()
            }
        }
        .refreshable {
            await self.startFeed()
        }
        .searchable(text: self.$queryString)
        .task(id: self.queryString) {
            await self.loadSuggestions()
        }
        .searchSuggestions {
            QuerySuggestionsView(suggestions: self.$querySuggestions)
        }
        .onSubmit(of: .search) {
            Task {
                await self.startFeed()
            }
        }
        // Add new image on upload.
        .onReceive(NotificationCenter.default.publisher(for: .addImage)) { output in
            guard let image = output.object as? IamagesImage else {
                return
            }
            self.splitViewModel.images.insert(
                IamagesImageAndMetadataContainer(id: image.id, image: image),
                at: 0
            )
        }
        .toolbar {
            #if targetEnvironment(macCatalyst)
            ToolbarItem {
                Button(action: {
                    Task {
                        await self.startFeed()
                    }
                }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .keyboardShortcut("r")
                .disabled(self.isBusy)
            }
            #endif
        }
    }
    
    var body: some View {
        Group {
            if self.globalViewModel.userInformation == nil {
                NotLoggedInView()
            } else {
                self.list
            }
        }
        .navigationTitle("Images")
        .fullScreenCover(isPresented: self.$globalViewModel.isUploadsPresented) {
            UploadsView()
        }
        .toolbar {
            ToolbarItem {
                Button(action: {
                    self.globalViewModel.isUploadsPresented = true
                }) {
                    Label("New upload", systemImage: "plus")
                }
            }
        }
    }
}

#if DEBUG
struct ImagesListView_Previews: PreviewProvider {
    static var previews: some View {
        ImagesListView()
            .environmentObject(GlobalViewModel())
            .environmentObject(SplitViewModel())
    }
}
#endif
