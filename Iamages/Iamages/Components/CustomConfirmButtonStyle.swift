import SwiftUI

struct CustomConfirmButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Font.body.weight(.medium))
            .padding(.vertical, 12)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14.0, style: .continuous)
                    .fill(Color.red)
            )
            .opacity(configuration.isPressed ? 0.4 : 1.0)
    }
}
