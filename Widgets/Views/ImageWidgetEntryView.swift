import SwiftUI
import WidgetKit

struct ImageWidgetEntryView : View {
    struct IdentifiableError: Identifiable {
        let id = UUID()
        let error: Error
    }
    
    var entry: ImageWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
            HStack {
                if self.entry.errors.isEmpty {
                    Text(self.entry.description ?? "No description")
                        .lineLimit(2)
                } else {
                    VStack {
                        ForEach(self.entry.errors.map({ IdentifiableError(error: $0) })) { idError in
                            Text(idError.error.localizedDescription)
                        }
                    }
                }
                Spacer()
            }
            .bold()
        }
        .padding()
        .shadow(radius: 6)
        .font(.subheadline)
        .foregroundColor(.white)
        .multilineTextAlignment(.leading)
        .background {
            if let image = self.entry.image {
                #if os(iOS)
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .opacity(0.6)
                #else
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .opacity(0.6)
                #endif
            } else {
                Rectangle()
                    .fill(.orange.gradient)
            }
        }
        .widgetURL(URL(string: "iamages://api/images/\(self.entry.id ?? "")/embed"))
    }
}


#if DEBUG
struct ImageWidgetEntryView_Previews: PreviewProvider {
    static var previews: some View {
        ImageWidgetEntryView(entry: ImageWidgetEntry())
            .previewContext(
                WidgetPreviewContext(family: .systemSmall)
            )
    }
}
#endif
