//
//  LoginView.swift
//  Orli
//
//  Created by mohammad ali panhwar on 23/06/2025.
//

import SwiftUI
import Firebase
import AuthenticationServices
import CryptoKit
import FirebaseAuth

struct LoginView: View {
    @StateObject var userManager = UserManager()

    @State private var email = ""
    @State private var password = ""
    @State private var currentNonce: String?
    @State private var currentAlert: AlertType?
    @State private var showAlert = false
    @State private var isLoading = false
    @State private var isLoggedIn = false
    @State private var appleSignInDelegate: AppleSignInDelegateWrapper?


    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 24) {
                // Title
                VStack(spacing: 8) {
                    Text("Welcome back")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color("Text"))
                    
                    Text("Sign in to your Orli account")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 40)
                
                // Email
                VStack(alignment: .leading, spacing: 6) {
                    Text("Email")
                        .font(.subheadline)

                    TextField("your.email@example.com", text: $email)
                        .keyboardType(.emailAddress)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .foregroundColor(Color("Text"))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                }
                
                // Password
                VStack(alignment: .leading, spacing: 6) {
                    Text("Password")
                        .font(.subheadline)

                    SecureField("●●●●●●●●", text: $password)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .foregroundColor(Color("Text"))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                }
                
                // Login button
                Button(action: {
                    // Login logic
                    loginWithEmailPassword()
                }) {
                    Text("Log in")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("Button"))
                        .cornerRadius(8)
                }
                
                // OR divider
                HStack {
                    Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.3))
                    Text("or").foregroundColor(.gray)
                    Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.3))
                }
                
                // Apple Sign In
                CustomAppleLoginButton { result in
                    switch result {
                    case .success(let (authorization, nonce)):
                        handleAppleLogin(authorization, nonce: nonce)
                    case .failure(let error):
                        currentAlert = .error(message: "Apple Sign-In failed: \(error.localizedDescription)")
                        showAlert = true
                    }
                }


                
                // Footer
                HStack {
                    Text("Don't have an account yet?")
                        .foregroundColor(.gray)
                    NavigationLink(destination: SignupView()) {
                        Text("Get started")
                            .foregroundColor(Color("Button"))
                    }
                    // Navigate to sign up
                    
                    
                }
                
                Spacer(minLength: 40)
            }
            .padding()
            .onTapGesture {
                UIApplication.shared.endEditing()
            }
            .background(Color("Primary"))
            // Alert Banner at the top
            if showAlert, let alert = currentAlert {
                AlertBanner(alert: alert)
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.easeInOut, value: showAlert)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            showAlert = false
                        }
                    }
            }
            
            // Loading Overlay Centered
            if isLoading {
                ZStack {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    LottieView(animationName: "loader")
                        .frame(width: 150, height: 150)
                }
                .transition(.opacity)
                .zIndex(1)
            }
            
        
            

        }
   
        .fullScreenCover(isPresented: $isLoggedIn) {
            TabBarView()
        }
    }

    // MARK: - Email Login

    func loginWithEmailPassword() {
        isLoading = true
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let user = result?.user {
                fetchOrCreateUserDocument(for: user)
            } else {
                print("❌ Email login failed: \(error?.localizedDescription ?? "Unknown error")")
                isLoading = false
                currentAlert = .error(message: "❌ Email login failed: \(error?.localizedDescription ?? "Unknown error")")
                showAlert = true
            }
        }
    }


 



    func handleAppleLogin(_ authResults: ASAuthorization, nonce: String) {
        isLoading = true

        if let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential,
           let identityToken = appleIDCredential.identityToken,
           let tokenString = String(data: identityToken, encoding: .utf8) {

            let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: tokenString, rawNonce: nonce)
            Auth.auth().signIn(with: credential) { result, error in
                if let user = result?.user {
                    fetchOrCreateUserDocument(for: user)
                } else {
                    print("❌ Apple Sign-In failed:", error?.localizedDescription ?? "")
                    isLoading = false
                    currentAlert = .error(message: "❌ Apple Sign-In failed: \(error?.localizedDescription ?? "")")
                    showAlert = true
                }
            }
        } else {
            isLoading = false
            currentAlert = .error(message: "❌ Failed to retrieve Apple credentials.")
            showAlert = true
        }
    }


    // MARK: - Firestore Integration

    func fetchOrCreateUserDocument(for user: User) {
        let db = Firestore.firestore()
        let docRef = db.collection("users").document(user.uid)

        docRef.getDocument { snapshot, error in
            if let document = snapshot, document.exists {
                let data = document.data() ?? [:]
                let localUser = LocalUser(
                    uid: user.uid,
                    fullName: data["fullName"] as? String ?? "",
                    email: data["email"] as? String ?? "",
                    backupEmail: data["backupEmail"] as? String ?? "",
                    profileImageBase64: data["profileImageBase64"] as? String
                )
                userManager.saveUser(localUser)
                isLoggedIn = true
                isLoading = false
            } else {
                let userData: [String: Any] = [
                    "uid": user.uid,
                    "email": user.email ?? "",
                    "fullName": user.displayName ?? "",
                    "profileImageBase64": "",
                    "createdAt": Timestamp(date: Date())
                ]
                docRef.setData(userData) { error in
                    if error == nil {
                        let localUser = LocalUser(
                            uid: user.uid,
                            fullName: user.displayName ?? "",
                            email: user.email ?? "",
                            backupEmail: "",
                            profileImageBase64: ""
                        )
                        userManager.saveUser(localUser)
                        isLoggedIn = true
                        isLoading = false
                    }
                }
            }
        }
    }

    // MARK: - Nonce Helpers for Apple

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


extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

class AppleSignInDelegateWrapper: NSObject, ASAuthorizationControllerDelegate {
    var onComplete: (Result<ASAuthorization, Error>) -> Void

    init(onComplete: @escaping (Result<ASAuthorization, Error>) -> Void) {
        self.onComplete = onComplete
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        onComplete(.success(authorization))
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        onComplete(.failure(error))
    }
}
