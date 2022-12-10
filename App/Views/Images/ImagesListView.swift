import SwiftUI

struct ImagesListView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    @Environment(\.refresh) private var refreshAction
    @Environment(\.isSearching) private var isSearching
    
    @ObservedObject var splitViewModel: SplitViewModel
    
    @State private var isLoginSheetPresented: Bool = false
    
    @State private var isFirstPageLoaded: Bool = false
    @State private var isBusy: Bool = false
    @State private var images: [IamagesImage] = []
    @State private var isEndOfFeed: Bool = false
    @State private var error: LocalizedAlertError?
    
    @State private var searchString: String = ""
    
    @ViewBuilder
    private var notLoggedIn: some View {
        IconAndInformationView(
            icon: "person.fill.questionmark",
            heading: "Login required",
            additionalViews: AnyView(
                Button("Login/signup") {
                    self.isLoginSheetPresented = true
                }
                .buttonStyle(.bordered)
            )
        )
    }
    
    private func pageFeed() async {
        self.isBusy = true
        
        do {
            let newImages: [IamagesImage] = try await self.globalViewModel.getImagesFeedPage(previousId: self.images.last?.id)
            self.images.append(contentsOf: newImages)
            if newImages.count < self.globalViewModel.defaultPageItemsLimit {
                self.isEndOfFeed = true
            }
        } catch {
            self.error = LocalizedAlertError(error: error)
        }

        self.isBusy = false
    }
    
    private func startFeed() async {
        self.splitViewModel.selectedImage = nil
        self.images = []
        await pageFeed()
    }
    
    @ViewBuilder
    private var list: some View {
        List(selection: self.$splitViewModel.selectedImage) {
            ForEach(self.$images) { image in
                NavigableImageView(image: image)
                    .task {
                        if !self.isBusy && !self.isEndOfFeed && self.images.last != image.wrappedValue {
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
                await pageFeed()
                self.isFirstPageLoaded = true
            }
        }
        .refreshable {
            await self.startFeed()
        }
        .onReceive(NotificationCenter.default.publisher(for: .editImage)) { output in
            guard let notification = output.object as? EditImageNotification,
                  let i = self.images.firstIndex(where: { $0.id == notification.id }) else {
                print("Couldn't parse edit image notification.")
                return
            }
            switch notification.edit.change {
            case .isPrivate:
                switch notification.edit.to {
                case .bool(let isPrivate):
                    self.images[i].isPrivate = isPrivate
                    if self.splitViewModel.selectedImage?.id == notification.id {
                        self.splitViewModel.selectedImage?.isPrivate = isPrivate
                    }
                default:
                    break
                }
            case .lock:
                switch notification.edit.to {
                case .bool(let isLocked):
                    self.images[i].lock.isLocked = isLocked
                    self.images[i].lock.version = nil
                case .string(_):
                    self.images[i].lock.isLocked = true
                    self.images[i].lock.version = notification.edit.lockVersion
                }
            case .description:
                switch notification.edit.to {
                case .string(let description):
                    if self.splitViewModel.selectedImage?.id == notification.id {
                        self.splitViewModel.selectedImageMetadata?.description = description
                    }
                default:
                    break
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .deleteImage)) { output in
            guard let id = output.object as? String,
                  let i = self.images.firstIndex(where: { $0.id == id }) else {
                print("Couldn't find image in list.")
                return
            }
            self.images.remove(at: i)
        }
        .toolbar {
            #if targetEnvironment(macCatalyst)
            ToolbarItem {
                if self.isBusy {
                    ProgressView()
                } else {
                    Button(action: {
                        Task {
                            await startFeed()
                        }
                    }) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .keyboardShortcut("r")
                }
            }
            #endif
        }
    }
    
    var body: some View {
        Group {
            if self.globalViewModel.userInformation == nil {
                self.notLoggedIn
            } else {
                self.list
            }
        }
        .navigationTitle("Images")
        .sheet(isPresented: self.$isLoginSheetPresented) {
            LoginSheetView(isPresented: self.$isLoginSheetPresented)
        }
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
