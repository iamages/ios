import WidgetKit
import SwiftUI

fileprivate struct SelectedImageWidgetProvider: TimelineProvider {
    struct NoSelectedWidgetImage: LocalizedError {
        var errorDescription: String? = NSLocalizedString("Select an image in Iamages", comment: "")
    }
    
    struct ImageNotFound: LocalizedError {
        var errorDescription: String? = NSLocalizedString("Selected image is missing", comment: "")
    }
    
    @AppStorage("selectedWidgetImageId", store: .iamagesGroup) var imageId: String?
    private let userManager = UserManager()
    private var jsond = JSONDecoder()
    
    init() {
        self.jsond.dateDecodingStrategy = .iso8601
    }
    
    func placeholder(in context: Context) -> ImageWidgetEntry {
        var entry = ImageWidgetEntry(
            description: "Mandarin"
        )
        if let data = NSDataAsset(name: "SelectedImageWidgetPlaceholder")?.data {
            entry.setImage(data: data, size: context.displaySize)
        }
        return entry
    }
    
    private func getSelectedImageEntry(context: Context) async -> ImageWidgetEntry {
        var entry = ImageWidgetEntry()
        if let imageId {
            var imageRequest = URLRequest(url: .apiRootUrl.appending(path: "/images/\(imageId)"))
            imageRequest.httpMethod = HTTPMethod.head.rawValue
            // Check if image is private or not.
            var requiresAuth = false
            do {
                let (_, response) = try await URLSession.shared.data(for: imageRequest)
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 404 {
                        // Prematurely return entry with error because image
                        // does not exist.
                        entry.errors.append(ImageNotFound())
                        return entry
                    } else if httpResponse.statusCode == 401 {
                        requiresAuth = true
                    }
                }
            } catch {
                // Ignore error here.
                print(error)
            }
            // Actually do the request
            imageRequest.httpMethod = HTTPMethod.get.rawValue
            do {
                if requiresAuth {
                    try await self.userManager.getUserToken(for: &imageRequest)
                }
                let image = try self.jsond.decode(
                    IamagesImage.self,
                    from: await URLSession.shared.data(for: imageRequest).0
                )
                
                // Set entry image ID, now that we know the image can be accessed.
                entry.id = image.id

                var thumbnailRequest = URLRequest(url: .apiRootUrl.appending(path: "/images/\(imageId)/download"))
                if requiresAuth {
                    try await self.userManager.getUserToken(for: &thumbnailRequest)
                }
                entry.setImage(
                    data: try await self.userManager.session.data(for: thumbnailRequest).0,
                    size: context.displaySize
                )
                var metadataRequest = URLRequest(
                    url: .apiRootUrl
                        .appending(path: "/images/\(imageId)/metadata")
                )
                if requiresAuth {
                    try await self.userManager.getUserToken(for: &metadataRequest)
                }
                entry.description = try self.jsond.decode(
                    IamagesImageMetadata.self,
                    from: await URLSession.shared.data(for: metadataRequest).0
                ).description
            } catch {
                entry.errors.append(error)
            }
        } else {
            entry.errors.append(NoSelectedWidgetImage())
        }
        return entry
    }
    
    @MainActor
    func getSnapshot(in context: Context, completion: @escaping (ImageWidgetEntry) -> Void) {
        if context.isPreview {
            completion(self.placeholder(in: context))
        } else {
            Task {
                completion(await self.getSelectedImageEntry(context: context))
            }
        }
    }
    
    @MainActor
    func getTimeline(in context: Context, completion: @escaping (Timeline<ImageWidgetEntry>) -> Void) {
        Task {
            completion(
                Timeline(
                    entries: [await self.getSelectedImageEntry(context: context)],
                    policy: .never
                )
            )
        }
    }
}

struct SelectedImageWidget: Widget {
    let kind = WidgetKind.selected.rawValue
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: self.kind,
            provider: SelectedImageWidgetProvider()
        ) { entry in
            ImageWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Selected Image")
        .description("Displays an image you have selected in Iamages.")
    }
}
