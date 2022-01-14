import WidgetKit
import SwiftUI

struct IamagesFileEntry: TimelineEntry {
    let date: Date
    var info: IamagesFile?
    var thumb: Data?
    
    init(date: Date) {
        self.date = date
    }
}

struct Provider: IntentTimelineProvider {
    #if DEBUG
    let apiRoot: String = "http://localhost:9999/iamages/api/v3"
    #else
    let apiRoot: String = "https://iamages.uber.space/iamages/api/v3"
    #endif
    
    let jsone = JSONEncoder()
    let jsond = JSONDecoder()
    
    init() {
        self.jsone.dateEncodingStrategy = .customISO8601
        self.jsond.dateDecodingStrategy = .customISO8601
    }

    func placeholder(in context: Context) -> IamagesFileEntry {
        IamagesFileEntry(date: Date())
    }
    
    func fetchEntryFromAPI (for configuration: ConfigureFeedWidgetIntent, completion: @escaping (IamagesFileEntry) -> ()) {
        let currentDate: Date = Date()
        var entry: IamagesFileEntry = IamagesFileEntry(date: currentDate)
        
        var url: String = "\(apiRoot)/feed/files"
        var httpMethod: String = "GET"
        switch configuration.feed {
        case .unknown, .latestFiles:
            url += "/latest"
            httpMethod = "POST"
        case .popularFiles:
            url += "/popular"
        case .randomFile:
            url += "/random"
        }
        
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = httpMethod
        if configuration.feed == .latestFiles {
            request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? self.jsone.encode(DatePaginationRequest(limit: 1, startDate: nil))
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil && 200...299 ~= (response as! HTTPURLResponse).statusCode && data != nil {
                let file: IamagesFile?
                if configuration.feed == .randomFile {
                    file = try? self.jsond.decode(IamagesFile.self, from: data!)
                } else {
                    file = (try? self.jsond.decode([IamagesFile].self, from: data!))?.first
                }
                if file != nil {
                    entry.info = file!
                    URLSession.shared.dataTask(with: URL(string: "\(apiRoot)/file/\(file!.id)/thumb")!) { data, response, error in
                        if error == nil && 200...299 ~= (response as! HTTPURLResponse).statusCode && data != nil {
                            entry.thumb = data!
                        }
                        completion(entry)
                    }
                    .resume()
                } else {
                    completion(entry)
                }
            } else {
                completion(entry)
            }
        }
        .resume()
    }

    func getSnapshot(for configuration: ConfigureFeedWidgetIntent, in context: Context, completion: @escaping (IamagesFileEntry) -> ()) {
        self.fetchEntryFromAPI(for: configuration) { entry in
            completion(entry)
        }
    }

    func getTimeline(for configuration: ConfigureFeedWidgetIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        self.fetchEntryFromAPI(for: configuration) { entry in
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

struct FeedWidgetEntryView : View {
    @AppStorage("isNSFWEnabled", store: UserDefaults(suiteName: "group.me.jkelol111.Iamages")) var isNSFWEnabled: Bool = true
    @AppStorage("isNSFWBlurred", store: UserDefaults(suiteName: "group.me.jkelol111.Iamages")) var isNSFWBlurred: Bool = true
    
    var entry: Provider.Entry

    var body: some View {
        if let info = self.entry.info {
            Group {
                if info.isNSFW && !self.isNSFWEnabled {
                    Image(systemName: "18.circle")
                        .imageScale(.large)
                        .widgetURL(URL(string: "iamages://feed")!)
                } else {
                    if let thumb = self.entry.thumb {
                        if info.isNSFW && self.isNSFWBlurred {
                            Image(uiImage: UIImage(data: thumb)!)
                                .resizable()
                                .scaledToFill()
                                .blur(radius: 6.0)
                                .colorMultiply(.red)
                        } else {
                            Image(uiImage: UIImage(data: thumb)!)
                                .resizable()
                                .scaledToFill()
                        }
                    } else {
                        Image(systemName: "questionmark.app.dashed")
                            .imageScale(.large)
                    }
                }
            }
            .widgetURL(URL(string: "iamages://view?type=file&id=\(info.id)"))
        } else {
            Image(systemName: "exclamationmark.triangle.fill")
                .imageScale(.large)
                .widgetURL(URL(string: "iamages://feed")!)
        }
    }
}

@main
struct FeedWidget: Widget {
    let kind: String = "me.jkelol111.Iamages.FeedWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(
            kind: self.kind,
            intent: ConfigureFeedWidgetIntent.self,
            provider: Provider()
        ) { entry in
            FeedWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Feed")
        .description("Shows the latest files in the selected public feed.")
    }
}
