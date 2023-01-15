import SwiftUI
import OrderedCollections

struct ImagesListView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    @EnvironmentObject private var splitViewModel: SplitViewModel

    @State private var isFirstPageLoaded: Bool = false
    @State private var isBusy: Bool = false
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
                            lastID: self.splitViewModel.images.keys.last
                        )
                    ),
                    contentType: .json,
                    authStrategy: .required
                ).0
            )
            if newImages.count < 6 {
                self.isEndOfFeed = true
            }
            for newImage in newImages {
                self.splitViewModel.images[newImage.id] = IamagesImageAndMetadataContainer(image: newImage)
            }
        } catch {
            self.error = LocalizedAlertError(error: error)
        }

        self.isBusy = false
    }
    
    private func startFeed() async {
        self.splitViewModel.selectedImage = nil
        self.splitViewModel.images = [:]
        self.isEndOfFeed = false
        await pageFeed()
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
            ForEach(self.$splitViewModel.images.values, id: \.image.id) { imageAndMetadata in
                NavigableImageView(imageAndMetadata: imageAndMetadata)
                    .task {
                        if !self.isEndOfFeed && self.splitViewModel.images.keys.last == imageAndMetadata.image.id {
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
            if !self.isFirstPageLoaded {
                await startFeed()
                self.isFirstPageLoaded = true
            }
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
        .refreshable {
            await self.startFeed()
        }
        .toolbar {
            #if targetEnvironment(macCatalyst)
            ToolbarItem {
                Button(action: {
                    Task {
                        await startFeed()
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
