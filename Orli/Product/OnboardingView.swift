
import SwiftUI

struct OnboardingView: View {
    @State private var currentIndex = 0
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding = false
    @State private var showPaywall = false


    var body: some View {
        VStack {
            // Pages
            TabView(selection: $currentIndex) {
                ForEach(Array(onboardingPages.enumerated()), id: \.offset) { index, page in
                    VStack(spacing: 24) {
                        Spacer()
                        if page.type == .multiMessageTypes {
                            MultiMessageTypesCard()
                            gradientTitle(page.title)
                            
                            Text(page.subtitle)
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                        }else{
                            LottieView(animationName: page.gifName, loopMode: .loop)
                                .frame(width: 220, height: 220)
                                .cornerRadius(12)
                            
                            gradientTitle(page.title)
                            
                            Text(page.subtitle)
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                        }
                       
                        
                        Spacer()
                    }
                    .background(Color("Primary"))
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))

            // Button - Placed AFTER the TabView
            Button(action: {
                if currentIndex < onboardingPages.count - 1 {
                    currentIndex += 1
                } else {
                   // hasSeenOnboarding = true
                    showPaywall = true
                }
            }) {
                Text(currentIndex == onboardingPages.count - 1 ? "Get Started" : "Continue")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("Button"))
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 40) // Space from page control dots
        }
        .navigationBarHidden(true)
        .background(Color("Primary").edgesIgnoringSafeArea(.all))
        .fullScreenCover(isPresented: $showPaywall) {
            TabBarView()
        }
        .onAppear {
            UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(named: "Button") // Active dot
            UIPageControl.appearance().pageIndicatorTintColor = UIColor.lightGray           // Inactive dots
        }

    }

    func gradientTitle(_ text: String) -> some View {
        LinearGradient(
            colors: [Color("Button"), Color("Button").opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .mask(
            Text(text)
                .font(.title)
                .bold()
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        )
        .frame(height: 40)
    }
}

struct MultiMessageTypesCard: View {
    
    @Environment(\.colorScheme) var colorScheme

    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(spacing: 16) {
                messageTypeRow(icon: "message", title: "Text Message", description: "Write heartfelt notes that deliveres in future.")
                messageTypeRow(icon: "audio", title: "Audio Message", description: "Record your voice to say what can’t be written.")
                messageTypeRow(icon: "video", title: "Video Message", description: "Capture moments and emotions in full motion.")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill( colorScheme == .dark
                       ? AnyShapeStyle(LinearGradient(
                           colors: [Color.black.opacity(0.6), Color("Button").opacity(0.3)],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing
                         ))
                       : AnyShapeStyle(Color(.systemGray6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color("Button").opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }

    @ViewBuilder
    func messageTypeRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            LottieView(animationName: icon, loopMode: .autoReverse)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(Color("Text"))

                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}


struct OnboardingPage: Identifiable {
    let id = UUID()
    let gifName: String // systemName or asset
    let title: String
    let subtitle: String
    let type: PageType
}

enum PageType {
    case standard
    case multiMessageTypes
}


let onboardingPages = [
    OnboardingPage(
        gifName: "time",
        title: "Time-Delayed Messages",
        subtitle: "Send heartfelt messages into the future and have them delivered exactly when they matter most.", type: .standard
    ),
    OnboardingPage(
        gifName: "bubble.left.and.bubble.right",
        title: "Multiple Message Types",
        subtitle: "Send text, audio, or video messages to create meaningful memories for your loved ones.", type: .multiMessageTypes
    ),
    OnboardingPage(
        gifName: "secure",
        title: "Secure & Private",
        subtitle: "We take privacy seriously. Your messages are safe and delivered only at the right time.", type: .standard
    )
]


