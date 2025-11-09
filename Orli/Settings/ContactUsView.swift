//
//  ContactUsView.swift
//  Orli
//
//  Created by mohammad ali panhwar on 22/06/2025.
//

import SwiftUI

struct ContactUsView: View {
    var body: some View {
            ZStack {
               // Color.black.edgesIgnoringSafeArea(.all) // Dark background

                VStack(alignment: .leading, spacing: 20) {
                  
                    gradientMaskedText("Contact Us")

                    Text("We're here to help with any questions you may have.")
                        .font(.body)
                        .foregroundColor(Color("Text"))
                        .padding(.bottom, 20)

                    VStack(alignment: .leading, spacing: 15) {
                        Text("Get in Touch")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(Color("Text"))

                        HStack(spacing: 10) {
                            Image(systemName: "envelope.fill") // Envelope icon
                                .foregroundColor(Color(red: 0.6, green: 0.4, blue: 1.0)) // Purple color
                                .font(.title3)

                            Text("orlisupport@proton.me")
                                .font(.body)
                                .foregroundColor(.white)
                        }
                        .padding(.vertical, 10) // Add some vertical padding to the email row

                        Text("Our support team typically responds within 24 hours during business days.")
                            .font(.footnote)
                            .foregroundColor(Color("Text"))
                            .padding(.top, 5) // Small padding above this text

                        Button(action: {
                            // Action for the "Email Us" button
                            openEmail(to: "orlisupport@proton.me")
                        }) {
                            Text("Email Us")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 30)
                                .background(Color(red: 0.6, green: 0.4, blue: 1.0)) // Purple button background
                                .cornerRadius(10)
                        }
                        .padding(.top, 15) // Padding above the button
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(15)
                    .padding(.horizontal) // Horizontal padding for the card
                }
                .padding(.horizontal) // General horizontal padding for the entire view
            }
            .background(Color("Primary"))

    }
    
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
    
    func openEmail(to address: String) {
           if let url = URL(string: "mailto:\(address)") {
               UIApplication.shared.open(url)
           }
       }
}
