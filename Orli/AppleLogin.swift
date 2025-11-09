//
//  AppleLogin.swift
//  Orli
//
//  Created by mohammad ali panhwar on 16/07/2025.
//

import SwiftUI
import AuthenticationServices
import CryptoKit
import FirebaseAuth

struct CustomAppleLoginButton: View {
    let onComplete: (Result<(ASAuthorization, String), Error>) -> Void
    @State private var currentNonce: String?

    var body: some View {
        Button(action: startAppleLogin) {
            HStack {
                Spacer()
                Image(systemName: "applelogo")
                    .font(.headline)
                Text("Sign in with Apple")
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding()
            .frame(height: 50)
            .background(Color.black)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white, lineWidth: 2)
            )
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .frame(maxWidth: .infinity)


    }

    func startAppleLogin() {
        let nonce = randomNonceString()
        currentNonce = nonce

        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let coordinator = AppleLoginCoordinator(onComplete: onComplete, nonce: nonce)
        AppleLoginCoordinator.shared = coordinator

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = coordinator
        controller.presentationContextProvider = coordinator
        controller.performRequests()
    }
    
    func randomNonceString(length: Int = 32) -> String {
        let charset: Array<Character> = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in UInt8.random(in: 0...255) }
            for random in randoms {
                if remainingLength == 0 { break }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }

    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }

}


class AppleLoginCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    static var shared: AppleLoginCoordinator?

    var onComplete: (Result<(ASAuthorization, String), Error>) -> Void
    var nonce: String

    init(onComplete: @escaping (Result<(ASAuthorization, String), Error>) -> Void, nonce: String) {
        self.onComplete = onComplete
        self.nonce = nonce
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        onComplete(.success((authorization, nonce)))
        Self.shared = nil
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        onComplete(.failure(error))
        Self.shared = nil
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.keyWindow ?? ASPresentationAnchor()
    }
}



