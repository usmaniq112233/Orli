import SwiftUI

struct FeaturesView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Title with gradient
                VStack(spacing: 8) {
                    titleWithGradient()
                    Text("Discover how our time capsule messaging platform helps you leave meaningful messages for loved ones—delivered exactly when they matter most.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Section title
                Text("Message Types")
                    .font(.title2)
                    .bold()
                    .foregroundColor(Color("Text"))

                // Cards
                VStack(spacing: 16) {
                    FeatureCard(
                        icon: "text.bubble",
                        title: "Text Messages",
                        description: "Create heartfelt written messages to share your thoughts, wisdom, and love with future generations.",
                        planLabel: "Available on Free Plan"
                    )
                    FeatureCard(
                        icon: "headphones",
                        title: "Audio Messages",
                        description: "Record your voice to share stories, advice, or simply to let loved ones hear you again.",
                        planLabel: "Premium Feature"
                    )
                    FeatureCard(
                        icon: "video",
                        title: "Video Messages",
                        description: "Create powerful video messages that capture your expressions, emotions, and presence for future moments.",
                        planLabel: "Premium Feature"
                    )
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .background(Color("Primary").edgesIgnoringSafeArea(.all))
    }

    func titleWithGradient() -> some View {
        let firstPart = "Orli Features: Connecting Through "
        let gradientPart = "Time"

        return (
            Text(firstPart)
                .foregroundColor(Color("Text"))
            + Text(gradientPart)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color("Button"), Color("Button").opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .font(.title)
        .bold()
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let planLabel: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(Color("Button"))

            Text(title)
                .font(.headline)
                .foregroundColor(Color("Text"))

            Text(description)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)

            Text(planLabel)
                .font(.footnote)
                .foregroundColor(Color("Button"))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color("Button").opacity(0.2), lineWidth: 1)
        )
    }
}
