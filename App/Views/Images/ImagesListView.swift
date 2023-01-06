import SwiftUI
import OrderedCollections

struct ImagesListView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    
    @ObservedObject var splitViewModel: SplitViewModel

    @State private var isFirstPageLoaded: Bool = false
    @State private var isBusy: Bool = false
    @State private var images: OrderedDictionary<String, IamagesImage> = [:]
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
                            lastID: self.images.keys.last
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
                self.images[newImage.id] = newImage
            }
        } catch {
            self.error = LocalizedAlertError(error: error)
        }

        self.isBusy = false
    }
    
    private func startFeed() async {
        self.splitViewModel.selectedImage = nil
        self.splitViewModel.selectedImageMetadata = nil
        self.images = [:]
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
            ForEach(self.images.elements, id: \.key) { image in
                NavigableImageView(image: image.value)
                    .task {
                        if !self.isEndOfFeed && self.images.keys.last == image.key {
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
        .onReceive(NotificationCenter.default.publisher(for: .editImage)) { output in
            guard let notification = output.object as? IamagesImageEdit.Notification else {
                print("Couldn't parse edit image notification.")
                return
            }
            switch notification.edit.change {
            case .isPrivate:
                switch notification.edit.to {
                case .bool(let isPrivate):
                    self.images[notification.id]?.isPrivate = isPrivate
                    if self.splitViewModel.selectedImage?.id == notification.id {
                        self.splitViewModel.selectedImage?.isPrivate = isPrivate
                    }
                default:
                    break
                }
            case .lock:
                switch notification.edit.to {
                case .bool(let isLocked):
                    self.images[notification.id]?.lock.isLocked = isLocked
                    self.images[notification.id]?.lock.version = nil
                    if self.splitViewModel.selectedImage?.id == notification.id {
                        self.splitViewModel.selectedImage?.lock.isLocked = isLocked
                        self.splitViewModel.selectedImage?.lock.version = nil
                    }
                case .string(_):
                    self.images[notification.id]?.lock.isLocked = true
                    self.images[notification.id]?.lock.version = notification.edit.lockVersion
                    if self.splitViewModel.selectedImage?.id == notification.id {
                        self.splitViewModel.selectedImage?.lock.isLocked = true
                        self.splitViewModel.selectedImage?.lock.version = notification.edit.lockVersion
                    }
                default:
                    break
                }
            case .description:
                switch notification.edit.to {
                case .string(let description):
                    if self.splitViewModel.selectedImage?.id == notification.id {
                        self.splitViewModel.selectedImageMetadata?.data.description = description
                    }
                default:
                    break
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .deleteImage)) { output in
            guard let id = output.object as? String else {
                return
            }
            withAnimation {
                self.images.removeValue(forKey: id)
            }
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
    }
}

#if DEBUG
struct ImagesListView_Previews: PreviewProvider {
    static var previews: some View {
        ImagesListView(splitViewModel: SplitViewModel())
            .environmentObject(GlobalViewModel())
    }
}
#endif
