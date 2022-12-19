import WidgetKit
import KeychainAccess
import SwiftUI

fileprivate struct NewestImagesWidgetProvider: TimelineProvider {
    struct EmptyData: LocalizedError {
        let url: URL
        var errorDescription: String? {
            NSLocalizedString("Could not fetch data for \(url.relativeString).", comment: "")
        }
    }
    
    private let jsond = JSONDecoder()
    private let userManager = UserManager()
    
    init() {
        self.jsond.dateDecodingStrategy = .iso8601
    }
    
    func placeholder(in context: Context) -> ImageWidgetEntry {
        var entry = ImageWidgetEntry(description: "Oranges")
        if let data = NSDataAsset(name: "NewestImagesWidgetPlaceholder")?.data {
            entry.setImage(data: data, size: context.displaySize)
        }
        return entry
    }
    
    private func getNewestImageEntry(context: Context) async -> ImageWidgetEntry {
        var entry = ImageWidgetEntry()
        
        var newestImage: IamagesImage?
        var lastId: String?
        
        while (newestImage == nil && entry.errors.isEmpty) {
            var feedUrl = URL.apiRootUrl.appending(path: "/images")
            if let lastId {
                feedUrl.append(queryItems: [
                    URLQueryItem(name: "last_id", value: lastId)
                ])
            }
            var request = URLRequest(url: feedUrl)
            do {
                try await self.userManager.getUserToken(for: &request)
                let images = try self.jsond.decode(
                    [IamagesImage].self,
                    from: await URLSession.shared.data(for: request).0
                )
                for image in images {
                    if !image.lock.isLocked {
                        newestImage = image
                        break
                    }
                }
                lastId = images.last?.id
            } catch {
                entry.errors.append(error)
            }
        }
        
        if let newestImage {
            entry.id = newestImage.id
            do {
                var thumbnailRequest = URLRequest(url: .apiRootUrl.appending(path: "/thumbnails/\(newestImage.id)"))
                if newestImage.isPrivate {
                    try await self.userManager.getUserToken(for: &thumbnailRequest)
                }
                entry.setImage(
                    data: try await self.userManager.session.data(for: thumbnailRequest).0,
                    size: context.displaySize
                )
                var metadataRequest = URLRequest(
                    url: .apiRootUrl
                        .appending(path: "/images/\(newestImage.id)")
                        .appending(queryItems: [
                            URLQueryItem(name: "type", value: "private")
                        ])
                )
                if newestImage.isPrivate {
                    try await self.userManager.getUserToken(for: &metadataRequest)
                }
                entry.description = try self.jsond.decode(
                    IamagesImageMetadata.self,
                    from: await URLSession.shared.data(for: metadataRequest).0
                ).description
            } catch {
                entry.errors.append(error)
            }
        }
        return entry
    }
    

    @MainActor
    func getSnapshot(in context: Context, completion: @escaping (ImageWidgetEntry) -> ()) {
        if context.isPreview {
            completion(self.placeholder(in: context))
        } else {
            Task {
                completion(await self.getNewestImageEntry(context: context))
            }
        }
    }

    @MainActor
    func getTimeline(in context: Context, completion: @escaping (Timeline<ImageWidgetEntry>) -> ()) {
        Task {
            let entry = await self.getNewestImageEntry(context: context)
            completion(
                Timeline(
                    entries: [entry],
                    policy: .after(
                        Calendar.current.date(
                            byAdding: .hour,
                            value: 1,
                            to: entry.date
                        )!
                    )
                )
            )
        }
    }
}

struct NewestImagesWidget: Widget {
    let kind: String = WidgetKind.newest.rawValue

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: self.kind,
            provider: NewestImagesWidgetProvider()
        ) { entry in
            ImageWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Newest Images")
        .description("Showcase your newest (non-locked) images.")
    }
}
