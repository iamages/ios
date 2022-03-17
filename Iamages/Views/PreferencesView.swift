import SwiftUI
import StoreKit
import SPConfetti
import Kingfisher
import WidgetKit

struct PreferencesView: View {
    @EnvironmentObject var dataObservable: APIDataObservable
    
    @AppStorage("isNSFWBlurred", store: UserDefaults(suiteName: "group.me.jkelol111.Iamages")) var isNSFWBlurred: Bool = false
    
    @AppStorage("uploadDefaults.isNSFW") var isNSFWDefault: Bool = false
    @AppStorage("uploadDefaults.isHidden") var isHiddenDefault: Bool = false
    @AppStorage("uploadDefaults.isPrivate") var isPrivateDefault: Bool = false
    
    @State var isTermsAlertPresented: Bool = false
    @State var isClearCacheAlertPresented: Bool = false
    @State var isResetWarningAlertPresented: Bool = false
    
    @State var isCacheBeingCleared: Bool = false

    @State var isTransactionSubscribeCompleted: Bool = false
    @State var areProductsLoading: Bool = false
    @State var productsLoadingErrorText: String?
    @State var products: [Product] = []
    @State var isPurchasingProduct: Bool = false
    @State var tipErrorText: String?
    @State var isTipErrorAlertPresented: Bool = false
    @State var isTipThanksAlertPresented: Bool = false
    @State var isTipConfettiPresented: Bool = false
    
    func clearImageCache () {
        self.isCacheBeingCleared = true
        KingfisherManager.shared.cache.clearCache {
            self.isCacheBeingCleared = false
        }
    }
    
    func resetAppSettings () {
        self.isNSFWBlurred = true
        self.isNSFWBlurred = false
        self.isHiddenDefault = false
        self.isPrivateDefault = false
    }
    
    func purchaseProduct (_ product: Product) async {
        self.isPurchasingProduct = true
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verificationResult):
                switch verificationResult {
                case .verified(let transaction):
                    self.isTipThanksAlertPresented = true
                    self.isTipConfettiPresented = true
                    await transaction.finish()
                case .unverified(let transaction, let verificationError):
                    self.tipErrorText = verificationError.localizedDescription
                    self.isTipErrorAlertPresented = true
                    await transaction.finish()
                }
            case .userCancelled:
                self.tipErrorText = "Please come back another time to the Tip Jar!"
                self.isTipErrorAlertPresented = true
            case .pending:
                break
            @unknown default:
                break
            }
        } catch {
            self.tipErrorText = error.localizedDescription
            self.isTipErrorAlertPresented = true
        }
        self.isPurchasingProduct = false
    }
    
    func refreshWidgets () {
        WidgetCenter.shared.reloadAllTimelines()
    }

    var body: some View {
        Form {
            Section(content: {
                Toggle("Blur NSFW Content", isOn: self.$isNSFWBlurred)
                    .disabled(!self.dataObservable.isLoggedIn)
            }, header: {
                Text("Viewing")
            }, footer: {
                Text("\(!self.dataObservable.isLoggedIn ? "You're not logged in. These settings will not be applied.\n\n" : "")NSFW options here will not take effect until you have explicitly enabled NSFW viewing on our website. (\(self.dataObservable.apiRoot)/user/nsfw_toggle)")
            })
            Section {
                Toggle(isOn: self.$isNSFWDefault) {
                    Text("NSFW (18+)")
                }
                Toggle(isOn: self.$isHiddenDefault) {
                    Text("Hidden")
                }
                Toggle(isOn: self.$isPrivateDefault) {
                    Text("Private")
                }
            } header: {
                Text("Upload defaults")
            } footer: {
                Text("These preferences will be applied to every new upload created after the changes were made.")
            }
            Section("Maintenance") {
                Button("Clear image cache") {
                    self.isClearCacheAlertPresented = true
                }
                .confirmationDialog(
                    "The image cache will be cleared and images will need to be reloaded.",
                    isPresented: self.$isClearCacheAlertPresented,
                    titleVisibility: .visible
                ) {
                    Button("Clear image cache", role: .destructive, action: self.clearImageCache)
                }
                .disabled(self.isCacheBeingCleared)
                Button("Refresh widgets", action: self.refreshWidgets)
                Button("Reset app preferences", role: .destructive) {
                    self.isResetWarningAlertPresented = true
                }
                .confirmationDialog(
                    "This will reset all your preferences to default.",
                    isPresented: self.$isResetWarningAlertPresented,
                    titleVisibility: .visible
                ) {
                    Button("Reset all preferences", role: .destructive, action: self.resetAppSettings)
                }
            }
            Section(content: {
                if self.areProductsLoading {
                    HStack {
                        ProgressView()
                            .padding(.trailing, 4)
                        Text("Loading tips...")
                    }
                } else {
                    if let productsLoadingErrorText: String = self.productsLoadingErrorText {
                        Text("**Loading tips failed!**\n\n\(productsLoadingErrorText)\n\nPlease relaunch the app to retry.")
                    } else {
                        ForEach(self.products) { product in
                            Button("\(product.displayName) (\(product.displayPrice))") {
                                Task {
                                    await self.purchaseProduct(product)
                                }
                            }
                            .disabled(self.isPurchasingProduct)
                        }
                    }
                }
            }, header: {
                Text("Tip Jar")
            }, footer: {
                Text("Your support helps us maintain Iamages for you and many others! Thank you!\n\nEvery:\n- **Small tip** can keep our servers running for 1 month, courtesy of Uberspace.\n- **Medium tip** will keep our developers fed and motivated to create new features.\n- **Large tip** will help us afford devices to test our apps on.")
            })
            #if !targetEnvironment(macCatalyst)
            Section(content: {
                HelpLinksView()
            }, header: {
                Text("Links + about")
            }, footer: {
                Text("**Iamages \(Bundle.main.version) (\(Bundle.main.build))**\n\(Bundle.main.copyright)")
            })
            #endif
        }
        .onChange(of: self.isNSFWBlurred) { _ in
            self.refreshWidgets()
        }
        .navigationTitle("Preferences")
        .customBindingAlert(title: "Tipping failed", message: self.$tipErrorText, isPresented: self.$isTipErrorAlertPresented)
        .customFixedAlert(title: "Thank you!", message: "Your tip will help us continue developing Iamages. Thank you for tipping!", isPresented: self.$isTipThanksAlertPresented)
        .confetti(
            isPresented: self.$isTipConfettiPresented,
            animation: .fullWidthToDown,
            particles: [.heart, .star],
            duration: 3
        )
        .confettiParticle(\.velocity, 600)
        .onAppear {
            if self.products.count != 3 {
                self.areProductsLoading = true
                Task {
                    do {
                        self.products = try await Product.products(for: [
                            "me.jkelol111.Iamages.Tips.Small",
                            "me.jkelol111.Iamages.Tips.Medium",
                            "me.jkelol111.Iamages.Tips.Large"
                        ])
                    } catch {
                        self.productsLoadingErrorText = error.localizedDescription
                    }
                    self.areProductsLoading = false
                }
            } else {
                print(self.products.count)
            }
            if !self.isTransactionSubscribeCompleted {
                Task.detached {
                    for await verificationResult in Transaction.updates {
                        guard case .verified(let transaction) = verificationResult else {
                            continue
                        }
                        DispatchQueue.main.async {
                            self.isTipThanksAlertPresented = true
                            self.isTipConfettiPresented = true
                        }
                        await transaction.finish()
                    }
                }
                self.isTransactionSubscribeCompleted = true
            }
        }
    }
}
