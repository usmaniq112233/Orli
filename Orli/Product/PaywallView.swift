import SwiftUI
import StoreKit
import PassKit

struct PaywallView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Headings
                gradientMaskedText("Simple, Transparent")
                gradientMaskedText("Pricing")

                Text("Choose the plan that works best for your time-delayed messaging needs")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(spacing: 20) {
                    // ✅ Premium Plan Always on Top
                    PlanCardView(
                        title: "Premium",
                        price: "$8.99",
                        subtitle: "/per year",
                        features: [
                            "Unlimited messages",
                            "Audio & video messages",
                            "Priority delivery",
                            "Multiple delivery methods",
                            "Advanced scheduling"
                        ],
                        isCurrent: subscriptionManager.purchasedProductIDs.contains("com.orli.premium"),
                        isPopular: !subscriptionManager.purchasedProductIDs.contains("com.orli.premium"),
                        isSubscribed: subscriptionManager.purchasedProductIDs.contains("com.orli.premium")
                    )

                    // ❌ Free Plan only if not subscribed
                    if !subscriptionManager.purchasedProductIDs.contains("com.orli.premium") {
                        PlanCardView(
                            title: "Free",
                            price: "$0",
                            subtitle: "/forever",
                            features: [
                                "5 messages per year",
                                "Text messages only",
                                "Basic scheduling",
                                "Email delivery"
                            ],
                            isCurrent: true,
                            isPopular: false,
                            isSubscribed: false
                        )
                    }
                    
                    VStack(spacing: 8) {
                               Text("By subscribing, you agree to our Terms of Use and Privacy Policy. Subscription renews automatically unless canceled at least 24 hours before the end of the current period.")
                                   .font(.footnote)
                                   .foregroundColor(.gray)
                                   .multilineTextAlignment(.center)

                               HStack(spacing: 16) {
                                   Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                                   Link("Privacy Policy", destination: URL(string: "https://future-echo-messages.lovable.app/privacy")!)
                               }
                               .font(.footnote)
                           }
                           .padding(.top, 20)
                           .padding(.horizontal)
                }
                .padding(.horizontal)
                
            }
            .padding()
        }
        .background(Color("Primary"))
    }

    // MARK: - Gradient Text Heading
    func gradientMaskedText(_ text: String) -> some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color("Button"), location: 0.0),
                .init(color: Color("Button").opacity(0.8), location: 0.5),
                .init(color: Color("Primary").opacity(0.3), location: 1.0)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .mask(
            Text(text)
                .font(.largeTitle)
                .bold()
                .multilineTextAlignment(.center)
        )
        .frame(height: 40)
    }
}


struct PlanCardView: View {
    let title: String
    let price: String
    let subtitle: String
    let features: [String]
    let isCurrent: Bool
    let isPopular: Bool
    let isSubscribed: Bool

    @EnvironmentObject var subscriptionManager: SubscriptionManager

    var body: some View {
        VStack(spacing: 12) {
            // 🔁 Replace "Most Popular" with "Current Plan" if subscribed
            if isCurrent {
                Text("Current Plan")
                    .font(.caption)
                    .bold()
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color("Button"))
                    .cornerRadius(10)
            } else if isPopular {
                Text("Most Popular")
                    .font(.caption)
                    .bold()
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color("Button"))
                    .cornerRadius(10)
            }

            Text(title)
                .font(.title2)
                .bold()
                .foregroundColor(Color("Text"))

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(price)
                    .font(.title)
                    .bold()
                    .foregroundColor(Color("Text"))
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(features, id: \.self) { feature in
                    Label(feature, systemImage: "checkmark")
                        .foregroundColor(Color("Button"))
                        .font(.subheadline)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            // 🔁 Button Logic
            if isCurrent && isSubscribed {
                Button(action: {
                    if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Text("Manage Subscription")
                        .foregroundColor(.blue)
                        .font(.footnote)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(10)
                }
            } else if !isCurrent && title == "Premium" {
                if let product = subscriptionManager.products.first(where: { $0.id == "com.orli.premium" }) {
                    Button(action: {
                        Task {
                            try? await subscriptionManager.purchase(product)
                        }
                    }) {
                        Text("Subscribe with Apple")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color("Button"))
                            .cornerRadius(10)
                    }
                }
            } else {
                // Free plan current state
              //  Text("Current Plan")
                   // .foregroundColor(.gray)
                   // .font(.footnote)
                   // .padding(.vertical, 8)
                   // .frame(maxWidth: .infinity)
                   // .background(Color(UIColor.systemGray6))
                   // .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isCurrent ? Color("Button") : Color.clear, lineWidth: 2)
        )
        .frame(maxWidth: .infinity)
    }
}


// MARK: - Native Apple Pay Button

struct ApplePayButtonView: UIViewRepresentable {
    func makeUIView(context: Context) -> PKPaymentButton {
        return PKPaymentButton(paymentButtonType: .subscribe, paymentButtonStyle: .automatic)
    }

    func updateUIView(_ uiView: PKPaymentButton, context: Context) {}
}

