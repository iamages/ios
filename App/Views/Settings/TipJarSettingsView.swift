import SwiftUI
import StoreKit
import SPConfetti

struct TipJarSettingsView: View {
    private struct IAPCancelledError: LocalizedError {
        let errorDescription: String? = "You're always welcome back to the tip jar!"
    }
    
    @Binding var isBusy: Bool

    @State private var iaps: [Product] = []
    @State private var isTipThanksAlertPresented: Bool = false
    @State private var error: LocalizedAlertError?
    
    private func purchaseIAP(_ iap: Product) async {
        self.isBusy = true
        do {
            let result = try await iap.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    self.isTipThanksAlertPresented = true
                    await transaction.finish()
                case .unverified(let transaction, let error):
                    await transaction.finish()
                    throw error
                }
            case .userCancelled:
                throw IAPCancelledError()
            case .pending:
                break
            @unknown default:
                break
            }
        } catch {
            self.error = LocalizedAlertError(error: error)
        }
        self.isBusy = false
    }
    
    private func getIAPEmoji(productName: String) -> String {
        switch productName {
        case "Small Tip":
            return "🍦"
        case "Medium Tip":
            return "🍰"
        case "Large Tip":
            return "🎂"
        default:
            return "🪙"
        }
    }
    
    var body: some View {
        Text("Hey there, I rely on these donations to keep the service alive.\nIf you find Iamages useful, please consider donating.")
            .onAppear {
                Task.detached {
                    for await verification in Transaction.updates {
                        guard case .verified(let transaction) = verification else {
                            continue
                        }
                        DispatchQueue.main.async {
                            self.isTipThanksAlertPresented = true
                        }
                        await transaction.finish()
                    }
                }
                Task {
                    self.isBusy = true
                    if self.iaps.count != 3 {
                        do {
                            self.iaps = try await Product.products(for: [
                                "me.jkelol111.Iamages.Tips.Large",
                                "me.jkelol111.Iamages.Tips.Medium",
                                "me.jkelol111.Iamages.Tips.Small"
                            ])
                        } catch {
                            self.error = LocalizedAlertError(error: error)
                        }
                    }
                    self.isBusy = false
                }
            }
            .errorAlert(error: self.$error)
            .alert("Thank you!", isPresented: self.$isTipThanksAlertPresented) {
                // OK button should be provided by default.
            } message: {
                Text("Your tip will go into keep Iamages alive and well for everyone.")
            }
            // Carefully tweaked confetti!
            .confetti(
                isPresented: self.$isTipThanksAlertPresented,
                animation: .fullWidthToDown,
                particles: [.heart, .star],
                duration: 3
            )
            .confettiParticle(\.velocity, 600)
        ForEach(self.iaps) { iap in
            Button(action: {
                Task {
                    await self.purchaseIAP(iap)
                }
            }) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(iap.displayPrice)
                            .bold()
                        Text(iap.description)
                    }
                    Spacer()
                    Text(self.getIAPEmoji(productName: iap.displayName))
                        .font(.largeTitle)
                }
            }
            .disabled(self.isBusy)
        }
    }
}

#if DEBUG
struct TipJarSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        TipJarSettingsView(isBusy: .constant(false))
    }
}
#endif
