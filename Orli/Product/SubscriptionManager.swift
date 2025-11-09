import StoreKit

@MainActor
class SubscriptionManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []

    static let shared = SubscriptionManager()
    
    /// Set to true if you want the app to behave like the user has premium access by default (e.g. for testing).
    private let isPremiumDefault = true
    
    private let premiumProductID = "com.orli.premium"

    init() {
        Task {
            await fetchProducts()
            await updatePurchasedProducts()
        }
    }

    func fetchProducts() async {
        do {
            let storeProducts = try await Product.products(for: [premiumProductID])
            products = storeProducts
        } catch {
            print("Failed to fetch products: \(error)")
        }
    }

    func updatePurchasedProducts() async {
        var activeProductIDs: Set<String> = []

        if isPremiumDefault {
            activeProductIDs.insert(premiumProductID)
        } else {
            for await result in Transaction.currentEntitlements {
                if case .verified(let transaction) = result {
                    activeProductIDs.insert(transaction.productID)
                }
            }
        }

        // Update published property once
        purchasedProductIDs = activeProductIDs
    }

    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            if case .verified(let transaction) = verification {
                await updatePurchasedProducts()
                print("Purchase successful: \(transaction)")
            }
        default:
            print("Purchase cancelled or failed")
        }
    }
}
