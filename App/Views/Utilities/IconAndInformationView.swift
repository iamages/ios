import SwiftUI

struct IconAndInformationView: View {
    let icon: String
    let heading: String
    var subheading: String? = nil
    var additionalViews: AnyView? = nil
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: self.icon)
                .font(.largeTitle)
            Text(self.heading)
                .font(.title2)
                .bold()
            if let subheading {
                Text(subheading)
            }
            if let additionalViews {
                additionalViews
            }
        }
        .multilineTextAlignment(.center)
    }
}

#if DEBUG
struct IconAndInformationView_Previews: PreviewProvider {
    static var previews: some View {
        IconAndInformationView(
            icon: "face.smiling",
            heading: "Hello there!",
            subheading: "This is an information view used throughout the app."
        )
    }
}
#endif
