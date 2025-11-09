//
//  FaceIDView.swift
//  Orli
//
//  Created by mohammad ali panhwar on 22/06/2025.
//

import LocalAuthentication
import SwiftUI

class FaceIDManager: ObservableObject {
    @AppStorage("useFaceID") var useFaceID: Bool = false
    @AppStorage("isFaceIDAuthenticated") var isFaceIDAuthenticated: Bool = false
    @Published var isAuthenticated: Bool = false
    @Published var error: FaceIDError?

    /// Call this when toggling Face ID ON in settings
    func toggleFaceID(to newValue: Bool) {
        if newValue {
            authenticateUser(reason: "Enable Face ID for quick login") { success in
                DispatchQueue.main.async {
                    if success {
                        self.useFaceID = true
                        self.isFaceIDAuthenticated = true
                    } else {
                        self.useFaceID = false
                        self.isFaceIDAuthenticated = false
                        self.error = FaceIDError(message: "Face ID authentication failed.")
                    }
                }
            }
        } else {
            useFaceID = false
            isFaceIDAuthenticated = false
        }
    }

    /// Call this in SplashView
    func authenticateIfNeeded() {
        guard useFaceID else {
            isAuthenticated = true
            return
        }

        authenticateUser(reason: "Authenticate to access Orli") { success in
            DispatchQueue.main.async {
                if success {
                    self.isAuthenticated = true
                    self.isFaceIDAuthenticated = true // optional
                } else {
                    self.isAuthenticated = false
                    self.error = FaceIDError(message: "Authentication failed.")
                }
            }
        }
    }


    /// Core Face ID/biometric auth function
    private func authenticateUser(reason: String, completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, _ in
                completion(success)
            }
        } else {
            completion(false)
        }
    }
}



struct FaceIDView: View {
    @StateObject private var auth = BiometricAuthenticator()

    var body: some View {
        Group {
            if auth.isAuthenticated {
                Text("Welcome! You’re authenticated 🎉")
            } else {
                VStack(spacing: 20) {
                    Text("Please authenticate to continue")
                    Button("Authenticate with Face ID") {
                        auth.authenticate()
                    }
                }
                .padding()
            }
        }
        .onAppear {
                auth.authenticate()
            }
            .alert(item: $auth.authError) { error in
                Alert(title: Text("Authentication Failed"), message: Text(error.message), dismissButton: .default(Text("OK")))
        }
    }
}


struct AuthError: Identifiable {
    let id = UUID()
    let message: String
}

class BiometricAuthenticator: ObservableObject {
    @Published var isAuthenticated = false
    @Published var authError: AuthError?

    func authenticate() {
        let context = LAContext()
        var error: NSError?

        // Check if device supports biometrics
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Use Face ID to unlock the app"

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        self.isAuthenticated = true
                    } else {
                        self.authError = AuthError(message: authenticationError?.localizedDescription ?? "Unknown error")
                    }
                }
            }
        } else {
            // Device doesn't support biometrics
            self.authError = AuthError(message: error?.localizedDescription ?? "Biometric authentication not available.")
        }
    }
}
