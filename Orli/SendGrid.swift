//
//  SendGrid.swift
//  Orli
//
//  Created by mohammad ali panhwar on 04/07/2025.
//

import Foundation

struct SendGridEmail: Codable {
    let personalizations: [Personalization]
    let from: EmailAddress
    let subject: String
    let content: [Content]

    struct Personalization: Codable {
        let to: [EmailAddress]
        let subject: String? // Subject can be in personalization or top-level
    }

    struct EmailAddress: Codable {
        let email: String
        let name: String?
    }

    struct Content: Codable {
        let type: String
        let value: String
    }
}


class SendGridService {
    // !! WARNING: Embedding API keys directly in client apps is NOT recommended for production.
    // Use a backend server to protect your API key in a real application.
    private let sendGridApiKey = ProcessInfo.processInfo.environment["SENDGRID_API_KEY"] ?? ""// Replace with your actual API key
    private let sendGridAPIURL = URL(string: "https://api.sendgrid.com/v3/mail/send")!

    enum SendEmailError: Error, LocalizedError {
        case invalidResponse
        case serverError(statusCode: Int, message: String)
        case encodingError(Error)
        case networkError(Error)
        case unknownError

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Invalid response from server."
            case .serverError(let statusCode, let message):
                return "SendGrid API error (\(statusCode)): \(message)"
            case .encodingError(let error):
                return "Failed to encode email data: \(error.localizedDescription)"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .unknownError:
                return "An unknown error occurred."
            }
        }
    }

    func sendEmail(to recipientEmail: String,
                   toName: String? = nil,
                   from senderEmail: String,
                   fromName: String? = nil,
                   subject: String,
                   body: String,
                   isHTML: Bool = false) async throws {

        let fromAddress = SendGridEmail.EmailAddress(email: senderEmail, name: fromName)
        let toAddress = SendGridEmail.EmailAddress(email: recipientEmail, name: toName)
        let content = SendGridEmail.Content(type: isHTML ? "text/html" : "text/plain", value: body)
        
        let personalization = SendGridEmail.Personalization(to: [toAddress], subject: nil) // Subject will be top-level

        let email = SendGridEmail(
            personalizations: [personalization],
            from: fromAddress,
            subject: subject,
            content: [content]
        )

        var request = URLRequest(url: sendGridAPIURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(sendGridApiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted // For debugging, remove in production
            request.httpBody = try encoder.encode(email)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw SendEmailError.invalidResponse
            }

            if !(200...299).contains(httpResponse.statusCode) {
                let responseString = String(data: data, encoding: .utf8) ?? "No response body"
                print("SendGrid Error Response: \(responseString)")
                throw SendEmailError.serverError(statusCode: httpResponse.statusCode, message: responseString)
            }

            // SendGrid returns an empty 202 Accepted response for successful sends.
            // If you need to debug, you can print the data, but it will be empty.
            print("Email sent successfully! Status Code: \(httpResponse.statusCode)")

        } catch let encodingError as EncodingError {
            throw SendEmailError.encodingError(encodingError)
        } catch {
            throw SendEmailError.networkError(error)
        }
    }
}

import SwiftUI

struct EmailComposerView: View {
    @State private var recipientEmail: String = ""
    @State private var recipientName: String = ""
    @State private var senderEmail: String = "your_verified_sender_email@example.com" // Must be a verified sender in SendGrid
    @State private var senderName: String = "Your App"
    @State private var emailSubject: String = ""
    @State private var emailBody: String = ""
    @State private var isShowingAlert = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""

    private let sendGridService = SendGridService() // Initialize your service

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Sender Details")) {
                    TextField("Your Email (Verified in SendGrid)", text: $senderEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Your Name", text: $senderName)
                }

                Section(header: Text("Recipient Details")) {
                    TextField("Recipient Email", text: $recipientEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Recipient Name (Optional)", text: $recipientName)
                }

                Section(header: Text("Email Content")) {
                    TextField("Subject", text: $emailSubject)
                    TextEditor(text: $emailBody)
                        .frame(height: 150)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }

                Button("Send Email") {
                    Task {
                        await sendEmail()
                    }
                }
                .disabled(recipientEmail.isEmpty || emailSubject.isEmpty || emailBody.isEmpty || senderEmail.isEmpty)
            }
            .navigationTitle("Send Email")
            .alert(isPresented: $isShowingAlert) {
                Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    func sendEmail() async {
        do {
            try await sendGridService.sendEmail(
                to: recipientEmail,
                toName: recipientName.isEmpty ? nil : recipientName,
                from: senderEmail,
                fromName: senderName.isEmpty ? nil : senderName,
                subject: emailSubject,
                body: emailBody
            )
            alertTitle = "Success"
            alertMessage = "Email sent successfully!"
            // Clear fields on success
            recipientEmail = ""
            recipientName = ""
            emailSubject = ""
            emailBody = ""
        } catch let error as SendGridService.SendEmailError {
            alertTitle = "Error"
            alertMessage = error.localizedDescription
        } catch {
            alertTitle = "Error"
            alertMessage = "An unexpected error occurred: \(error.localizedDescription)"
        }
        isShowingAlert = true
    }
}   
