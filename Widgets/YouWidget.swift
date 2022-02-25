import WidgetKit
import SwiftUI
import KeychainSwift

struct IamagesFileAndThumb {
    let info: IamagesFile
    var thumb: Data?
}

struct IamagesUserEntry: TimelineEntry {
    let date: Date
    var files: [IamagesFileAndThumb]?
}

struct YouWidgetProvider: TimelineProvider {
    #if DEBUG
    let apiRoot: String = "http://localhost:9999/iamages/api/v3"
    #else
    let apiRoot: String = "https://iamages.uber.space/iamages/api/v3"
    #endif

    let keychain: KeychainSwift = KeychainSwift(keyPrefix: "iamages_")
    let jsone = JSONEncoder()
    let jsond = JSONDecoder()
    
    init() {
        self.keychain.accessGroup = "group.me.jkelol111.Iamages"
        self.jsone.dateEncodingStrategy = .customISO8601
        self.jsond.dateDecodingStrategy = .customISO8601
    }

    func placeholder(in context: Context) -> IamagesUserEntry {
        IamagesUserEntry(date: Date())
    }
    
    func fetchEntryFromAPI(completion: @escaping (IamagesUserEntry) -> ()) {
        let currentDate: Date = Date()
        var entry: IamagesUserEntry = IamagesUserEntry(date: currentDate)
        if let username = self.keychain.get("username"), let password = self.keychain.get("password") {
            var request = URLRequest(url: URL(string: "\(self.apiRoot)/user/\(username.urlEncode())/files")!)
            request.httpMethod = "POST"
            request.addValue("Basic " + "\(username):\(password)".data(using: .utf8)!.base64EncodedString(), forHTTPHeaderField: "Authorization")
            request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? self.jsone.encode(DatePaginationRequest(limit: 6, startDate: nil))
            URLSession.shared.dataTask(with: request) { data, response, error in
                if error == nil && 200...299 ~= (response as! HTTPURLResponse).statusCode && data != nil {
                    if let files = try? self.jsond.decode([IamagesFile].self, from: data!) {
                        entry.files = []
                        var tries: Int = 0 {
                            didSet {
                                if files.count == tries {
                                    completion(entry)
                                }
                            }
                        }
                        for file in files {
                            URLSession.shared.dataTask(with: URL(string: "\(self.apiRoot)/file/\(file.id)/thumb")!) { data, response, error in
                                if error == nil && 200...299 ~= (response as! HTTPURLResponse).statusCode && data != nil {
                                    entry.files?.append(IamagesFileAndThumb(info: file, thumb: data!))
                                }
                                tries += 1
                            }
                            .resume()
                        }
                    }
                } else {
                    completion(entry)
                }
            }
            .resume()
        } else {
            completion(entry)
        }
    }

    func getSnapshot(in context: Context, completion: @escaping (IamagesUserEntry) -> ()) {
        self.fetchEntryFromAPI { entry in
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        self.fetchEntryFromAPI { entry in
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

struct YouWidgetEntryView : View {
    var entry: YouWidgetProvider.Entry

    var body: some View {
        Group {
            if let files = entry.files {
                GeometryReader { reader in
                    LazyVGrid(columns: .init(repeating: .init(.flexible(), spacing: 0, alignment: .center), count: 3), spacing: 0) {
                        ForEach(files, id: \.info.id) { file in
                            WidgetFileThumbnailView(file: file.info, thumb: file.thumb)
                                .frame(width: reader.size.width / 3, height: reader.size.height / 2, alignment: .center)
                                .clipped()
                        }
                    }
                }
            } else {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.largeTitle)
                    .privacySensitive(false)
            }
        }
        .widgetURL(URL(string: "iamages://you")!)
    }
}

struct YouWidget: Widget {
    let kind: String = "me.jkelol111.Iamages.YouWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: YouWidgetProvider()) { entry in
            YouWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Your files")
        .description("Shows up to 6 files you have uploaded recently.")
    }
}
